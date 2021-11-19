#include "sqlite3.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define ISSPACE(X) isspace((unsigned char)(X))
#define ISDIGIT(X) isdigit((unsigned char)(X))

#if SQLITE_VERSION_NUMBER<3005000
# define sqlite3_int64 sqlite_int64
#endif

/* All global state is held in this structure */
static struct Global {
  sqlite3 *db;               /* The open database connection */
  sqlite3_stmt *pStmt;       /* Current SQL statement */
  sqlite3_int64 iStart;      /* Start-time for the current test */
  sqlite3_int64 iTotal;      /* Total time */
  unsigned int x, y;         /* Pseudo-random number generator state */
  int nResult;               /* Size of the current result */
  char zResult[3000];        /* Text of the current result */
} g;

/* Print an error message and exit */
static void fatal_error(const char *zMsg, ...){
  va_list ap;
  va_start(ap, zMsg);
  vfprintf(stderr, zMsg, ap);
  va_end(ap);
  exit(1);
}

/*
** Return the value of a hexadecimal digit.  Return -1 if the input
** is not a hex digit.
*/
static int hexDigitValue(char c){
  if( c>='0' && c<='9' ) return c - '0';
  if( c>='a' && c<='f' ) return c - 'a' + 10;
  if( c>='A' && c<='F' ) return c - 'A' + 10;
  return -1;
}

/* Provide an alternative to sqlite3_stricmp() in older versions of
** SQLite */
#if SQLITE_VERSION_NUMBER<3007011
# define sqlite3_stricmp strcmp
#endif

/*
** Interpret zArg as an integer value, possibly with suffixes.
*/
static int integerValue(const char *zArg){
  sqlite3_int64 v = 0;
  static const struct { char *zSuffix; int iMult; } aMult[] = {
    { "KiB", 1024 },
    { "MiB", 1024*1024 },
    { "GiB", 1024*1024*1024 },
    { "KB",  1000 },
    { "MB",  1000000 },
    { "GB",  1000000000 },
    { "K",   1000 },
    { "M",   1000000 },
    { "G",   1000000000 },
  };
  int i;
  int isNeg = 0;
  if( zArg[0]=='-' ){
    isNeg = 1;
    zArg++;
  }else if( zArg[0]=='+' ){
    zArg++;
  }
  if( zArg[0]=='0' && zArg[1]=='x' ){
    int x;
    zArg += 2;
    while( (x = hexDigitValue(zArg[0]))>=0 ){
      v = (v<<4) + x;
      zArg++;
    }
  }else{
    while( isdigit(zArg[0]) ){
      v = v*10 + zArg[0] - '0';
      zArg++;
    }
  }
  for(i=0; i<sizeof(aMult)/sizeof(aMult[0]); i++){
    if( sqlite3_stricmp(aMult[i].zSuffix, zArg)==0 ){
      v *= aMult[i].iMult;
      break;
    }
  }
  if( v>0x7fffffff ) fatal_error("parameter too large - max 2147483648");
  return (int)(isNeg? -v : v);
}

/* Return the current wall-clock time, in milliseconds */
sqlite3_int64 speedtest1_timestamp(void){
#if SQLITE_VERSION_NUMBER<3005000
  return 0;
#else
  static sqlite3_vfs *clockVfs = 0;
  sqlite3_int64 t;
  if( clockVfs==0 ) clockVfs = sqlite3_vfs_find(0);
#if SQLITE_VERSION_NUMBER>=3007000
  if( clockVfs->iVersion>=2 && clockVfs->xCurrentTimeInt64!=0 ){
    clockVfs->xCurrentTimeInt64(clockVfs, &t);
  }else
#endif
  {
    double r;
    clockVfs->xCurrentTime(clockVfs, &r);
    t = (sqlite3_int64)(r*86400000.0);
  }
  return t;
#endif
}

/* Return a pseudo-random unsigned integer */
unsigned int speedtest1_random(void){
  g.x = (g.x>>1) ^ ((1+~(g.x&1)) & 0xd0000001);
  g.y = g.y*1103515245 + 12345;
  return g.x ^ g.y;
}

/* The speedtest1_numbername procedure below converts its argment (an integer)
** into a string which is the English-language name for that number.
** The returned string should be freed with sqlite3_free().
**
** Example:
**
**     speedtest1_numbername(123)   ->  "one hundred twenty three"
*/
int speedtest1_numbername(unsigned int n, char *zOut, int nOut){
  static const char *ones[] = {  "zero", "one", "two", "three", "four", "five", 
                  "six", "seven", "eight", "nine", "ten", "eleven", "twelve", 
                  "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
                  "eighteen", "nineteen" };
  static const char *tens[] = { "", "ten", "twenty", "thirty", "forty",
                 "fifty", "sixty", "seventy", "eighty", "ninety" };
  int i = 0;

  if( n>=1000000000 ){
    i += speedtest1_numbername(n/1000000000, zOut+i, nOut-i);
    sqlite3_snprintf(nOut-i, zOut+i, " billion");
    i += (int)strlen(zOut+i);
    n = n % 1000000000;
  }
  if( n>=1000000 ){
    if( i && i<nOut-1 ) zOut[i++] = ' ';
    i += speedtest1_numbername(n/1000000, zOut+i, nOut-i);
    sqlite3_snprintf(nOut-i, zOut+i, " million");
    i += (int)strlen(zOut+i);
    n = n % 1000000;
  }
  if( n>=1000 ){
    if( i && i<nOut-1 ) zOut[i++] = ' ';
    i += speedtest1_numbername(n/1000, zOut+i, nOut-i);
    sqlite3_snprintf(nOut-i, zOut+i, " thousand");
    i += (int)strlen(zOut+i);
    n = n % 1000;
  }
  if( n>=100 ){
    if( i && i<nOut-1 ) zOut[i++] = ' ';
    sqlite3_snprintf(nOut-i, zOut+i, "%s hundred", ones[n/100]);
    i += (int)strlen(zOut+i);
    n = n % 100;
  }
  if( n>=20 ){
    if( i && i<nOut-1 ) zOut[i++] = ' ';
    sqlite3_snprintf(nOut-i, zOut+i, "%s", tens[n/10]);
    i += (int)strlen(zOut+i);
    n = n % 10;
  }
  if( n>0 ){
    if( i && i<nOut-1 ) zOut[i++] = ' ';
    sqlite3_snprintf(nOut-i, zOut+i, "%s", ones[n]);
    i += (int)strlen(zOut+i);
  }
  if( i==0 ){
    sqlite3_snprintf(nOut-i, zOut+i, "zero");
    i += (int)strlen(zOut+i);
  }
  return i;
}


/* Start a new test case */
#define NAMEWIDTH 60
static const char zDots[] =
  ".......................................................................";
void speedtest1_begin_test(int iTestNum, const char *zTestName, ...){
  int n = (int)strlen(zTestName);
  char *zName;
  va_list ap;
  va_start(ap, zTestName);
  zName = sqlite3_vmprintf(zTestName, ap);
  va_end(ap);
  n = (int)strlen(zName);
  if( n>NAMEWIDTH ){
    zName[NAMEWIDTH] = 0;
    n = NAMEWIDTH;
  }
  printf("%4d - %s%.*s ", iTestNum, zName, NAMEWIDTH-n, zDots);
  fflush(stdout);
  sqlite3_free(zName);
  g.nResult = 0;
  g.iStart = speedtest1_timestamp();
  g.x = 0xad131d0b;
  g.y = 0x44f9eac8;
}

/* Complete a test case */
void speedtest1_end_test(void){
  sqlite3_int64 iElapseTime = speedtest1_timestamp() - g.iStart;
  g.iTotal += iElapseTime;
  printf("\t%4d.%03d\n", (int)(iElapseTime/1000), (int)(iElapseTime%1000));
  if( g.pStmt ){
    sqlite3_finalize(g.pStmt);
    g.pStmt = 0;
  }
}

/* Report end of testing */
void speedtest1_final(void){
  printf("       TOTAL%.*s %4d.%03ds\n", NAMEWIDTH-5, zDots,
         (int)(g.iTotal/1000), (int)(g.iTotal%1000));
}

/* Run SQL */
void speedtest1_exec(const char *zFormat, ...){
  va_list ap;
  char *zSql;
  va_start(ap, zFormat);
  zSql = sqlite3_vmprintf(zFormat, ap);
  va_end(ap);

  char *zErrMsg = 0;
  int rc = sqlite3_exec(g.db, zSql, 0, 0, &zErrMsg);
  if( zErrMsg ) fatal_error("SQL error: %s\n%s\n", zErrMsg, zSql);
  if( rc!=SQLITE_OK ) fatal_error("exec error: %s\n", sqlite3_errmsg(g.db));
  
  sqlite3_free(zSql);
}

/* Prepare an SQL statement */
void speedtest1_prepare(const char *zFormat, ...){
  va_list ap;
  char *zSql;
  va_start(ap, zFormat);
  zSql = sqlite3_vmprintf(zFormat, ap);
  va_end(ap);
  
  int rc;
  if( g.pStmt ) sqlite3_finalize(g.pStmt);
  rc = sqlite3_prepare_v2(g.db, zSql, -1, &g.pStmt, 0);
  if( rc ){
    fatal_error("SQL error: %s\n", sqlite3_errmsg(g.db));
  }

  sqlite3_free(zSql);
}

/* Run an SQL statement previously prepared */
void speedtest1_run(void){
  int i, n, len;
  assert( g.pStmt );
  g.nResult = 0;
  while( sqlite3_step(g.pStmt)==SQLITE_ROW ){
    n = sqlite3_column_count(g.pStmt);
    for(i=0; i<n; i++){
      const char *z = (const char*)sqlite3_column_text(g.pStmt, i);
      if( z==0 ) z = "nil";
      len = (int)strlen(z);
      if( g.nResult+len<sizeof(g.zResult)-2 ){
        if( g.nResult>0 ) g.zResult[g.nResult++] = ' ';
        memcpy(g.zResult + g.nResult, z, len+1);
        g.nResult += len;
      }
    }
  }
  sqlite3_reset(g.pStmt);
}

#ifndef SQLITE_OMIT_DEPRECATED
/* The sqlite3_trace() callback function */
static void traceCallback(void *NotUsed, const char *zSql){
  int n = (int)strlen(zSql);
  while( n>0 && (zSql[n-1]==';' || ISSPACE(zSql[n-1])) ) n--;
  fprintf(stderr,"%.*s;\n", n, zSql);
}
#endif /* SQLITE_OMIT_DEPRECATED */

/* Substitute random() function that gives the same random
** sequence on each run, for repeatability. */
static void randomFunc(
  sqlite3_context *context,
  int NotUsed,
  sqlite3_value **NotUsed2
){
  sqlite3_result_int64(context, (sqlite3_int64)speedtest1_random());
}

/*
** The main and default testset
*/
void testset_main(void){
  int i;                        /* Loop counter */
  int n;                        /* iteration count */
  int maxb;                     /* Maximum swizzled value */

  n = 5000;
  speedtest1_begin_test(100, "%d INSERTs into table with no index", n);
  //speedtest1_exec("BEGIN");
#if 1
  speedtest1_exec("CREATE TABLE tab (id INTEGER PRIMARY KEY, text TEXT NOT NULL);");
#endif
  speedtest1_prepare("INSERT INTO tab VALUES (null, 'value');");
  for(i=1; i<=n; i++){
    speedtest1_run();
  }
  //speedtest1_exec("COMMIT");
  speedtest1_end_test();
}

#if SQLITE_VERSION_NUMBER<3006018
#  define sqlite3_sourceid(X) "(before 3.6.18)"
#endif

int main(int argc, char **argv){
  int mmapSize = 0;             /* How big of a memory map to use */
  const char *zTSet = "main";   /* Which --testset torun */
  const char *zDbName = 0;      /* Name of the test database */

  int i;                        /* Loop counter */
  int rc;                       /* API return code */

  /* Display the version of SQLite being tested */
  printf("-- Speedtest1 for SQLite %s %.50s\n",
         sqlite3_libversion(), sqlite3_sourceid());

  /* Process command-line arguments */
  for(i=1; i<argc; i++){
    const char *z = argv[i];
    if( z[0]=='-' ){
      do{ z++; }while( z[0]=='-' );
      if( strcmp(z, "help")==0 || strcmp(z,"?")==0 ){
        exit(0);
#if SQLITE_VERSION_NUMBER>=3007017
      }else if( strcmp(z, "mmap")==0 ){
        if( i>=argc-1 ) fatal_error("missing argument on %s\n", argv[i]);
        mmapSize = integerValue(argv[++i]);
 #endif
      }else{
        fatal_error("unknown option: %s\nUse \"%s -?\" for help\n",
                    argv[i], argv[0]);
      }
    }else if( zDbName==0 ){
      zDbName = argv[i];
    }else{
      fatal_error("surplus argument: %s\nUse \"%s -?\" for help\n",
                  argv[i], argv[0]);
    }
  }
  //if( zDbName!=0 ) unlink(zDbName);
  sqlite3_initialize();

  /* Circumvent a bug in Unikraft */
  int fd = open(zDbName, O_CREAT);
  close(fd);

  /* Open the database and the input file */
  if( sqlite3_open(zDbName, &g.db) ){
    fatal_error("Cannot open database file: %s\n", zDbName);
  }

  /* Set database connection options */
  sqlite3_create_function(g.db, "random", 0, SQLITE_UTF8, 0, randomFunc, 0, 0);
  if( mmapSize>0 ){
    speedtest1_exec("PRAGMA mmap_size=%d", mmapSize);
  }

  if( strcmp(zTSet,"main")==0 ){
    testset_main();
  }else{
    fatal_error("unknown testset: \"%s\"\n"
                "Choices: cte debug1 fp main orm rtree trigger\n",
                 zTSet);
  }
  speedtest1_final();

  sqlite3_close(g.db);

  /* Release memory */
  return 0;
}
