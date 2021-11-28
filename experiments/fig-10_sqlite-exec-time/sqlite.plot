#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 650,250 font 'Arial,20'
set output '/out/sqlite.svg'

set grid

# Make the x axis labels easier to read.
set xtics font ",16" nomirror rotate by 20 scale 0 right
set ytics nomirror

# remove useless margins
set bmargin 1.5
set lmargin 7
set rmargin 1
#set tmargin 0.5

# offsets reduces the space at the extreme left & right borders
# to minimize white space
set offsets -0.5, -0.5, 0, 0

# Select histogram data
set style histogram rowstacked
set style data histogram

# Bar style
set style fill pattern border -1
set boxwidth 0.5

# make sure that the legend doesn't take too much space
unset key
set key samplen 1.5 outside above center horizontal font ",18"

# important to display labels
set datafile missing '-'

# uncomment this to get the title
#set title "Time to perform 5000 INSERTs in SQLite."

# ensure that y label doesn't take too much space
set ylabel "SQLite execution time (s)" offset 2,0
set lmargin 7

set yrange [0:2.5]
set xrange [0:14]

set label "Unikraft"    at 0.750,2.25 font ",18"
set label "Chrysalis"   at 4.050,2.25 font ",18"
set label "Linux"       at 7.450,2.25 font ",18"
set label "SeL4/"       at 9.400,2.25 font ",18"
set label "Genode"      at 9.200,2.00 font ",18"
set label "CubicleOS"   at 11.45,2.25 font ",18"

set label ".052"  at 0.600,0.232 font ",16"
set label ".801"  at 1.550,0.981 font ",16"
set label ".055"  at 3.550,0.235 font ",16"
set label ".112"  at 4.550,0.292 font ",16"
set label ".176"  at 5.550,0.356 font ",16"
set label ".173"  at 7.550,0.353 font ",16"
set label ".352"  at 9.550,0.532 font ",16"
set label ".662"  at 11.55,0.842 font ",16"
set label "1.6"   at 12.71,1.780 font ",16"

set arrow from 3,  graph 0 to 3, graph 1 nohead
set arrow from 7,  graph 0 to 7, graph 1 nohead
set arrow from 9,  graph 0 to 9, graph 1 nohead
set arrow from 11, graph 0 to 11, graph 1 nohead

plot "results/sqlite.dat" \
                  every 9::0 using 1:3:xtic(2) with boxes fs pattern 1 lc "#91c6e7" title "QEMU/KVM", \
               "" every 9::1 using 1:3:xtic(2) with boxes fs pattern 6 lc "#a2d9d1" notitle, \
               "" every 9::2 using 1:3:xtic(2) with boxes fs pattern 1 lc "#91c6e7" notitle, \
               "" every 9::3 using 1:3:xtic(2) with boxes fs pattern 1 lc "#91c6e7" notitle, \
               "" every 9::4 using 1:3:xtic(2) with boxes fs pattern 6 lc "#a2d9d1" title "linuxu",   \
               "" every 9::5 using 1:3:xtic(2) with boxes fs pattern 2 lc "#d18282" title "Process",  \
               "" every 9::6 using 1:3:xtic(2) with boxes fs pattern 1 lc "#91c6e7" notitle,   \
               "" every 9::7 using 1:3:xtic(2) with boxes fs pattern 6 lc "#a2d9d1" notitle,   \
               "" every 9::8 using 1:3:xtic(2) with boxes fs pattern 6 lc "#a2d9d1" notitle
