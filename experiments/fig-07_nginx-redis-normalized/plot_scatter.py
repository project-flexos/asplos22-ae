import sys
import os
import csv
import matplotlib.pyplot as plt

def check_equal_permutations(perm1, perm2):
    res1 = ""
    for i in perm1.keys():
        res1 += perm1[i]
    res2 = ""
    for j in perm2.keys():
        res2 += perm2[j]
    return res1 == res2
        
def collate(permutations_file_redis=None, permutations_file_nginx=None, results_file_nginx=None, results_file_redis=None):
  if not os.path.isfile(permutations_file_nginx):
    print("Cannot find: %s" % permutations_file_nginx)
    sys.exit(1)

  if not os.path.isfile(permutations_file_redis):
    print("Cannot find: %s" % permutations_file_redis)
    sys.exit(1)
 
  permutations_nginx = {}
 
  with open(permutations_file_nginx, 'r') as csvfile:
    print("Processing %s..." % permutations_file_nginx)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      permutations_nginx[row[0]] = (dict(zip(cols[1:], row[1:])))
      permutations_nginx[row[0]]['spec'] = (dict(zip(cols[1:], row[1:])))

  max_nginx = 0
  with open(results_file_nginx, 'r') as csvfile:
    print("Processing %s..." % results_file_nginx)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      data = dict(zip(cols[1:], row[1:]))
 
      if row[0] not in permutations_nginx:
        print("Missing result from permutation: %s" % row[0])
        continue
 
      if data["METHOD"] not in permutations_nginx[row[0]]:
        permutations_nginx[row[0]][data["METHOD"]] = {}
      
      if data["CHUNK"] not in permutations_nginx[row[0]][data["METHOD"]]:
        permutations_nginx[row[0]][data["METHOD"]][data["CHUNK"]] = []
 
      if float(data["VALUE"]) > max_nginx:
          max_nginx = float(data["VALUE"])

      permutations_nginx[row[0]][data["METHOD"]][data["CHUNK"]].append(
        float(data["VALUE"])
      )


  permutations_redis = {}
 
  with open(permutations_file_redis, 'r') as csvfile:
    print("Processing %s..." % permutations_file_redis)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      permutations_redis[row[0]] = (dict(zip(cols[1:], row[1:])))
      permutations_redis[row[0]]['spec'] = (dict(zip(cols[1:], row[1:])))

  max_redis = 0

  with open(results_file_redis, 'r') as csvfile:
    print("Processing %s..." % results_file_redis)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      data = dict(zip(cols[1:], row[1:]))
 
      if row[0] not in permutations_redis:
        print("Missing result from permutation: %s" % row[0])
        continue
 
      if data["METHOD"] not in permutations_redis[row[0]]:
        permutations_redis[row[0]][data["METHOD"]] = {}
      
      if data["CHUNK"] not in permutations_redis[row[0]][data["METHOD"]]:
        permutations_redis[row[0]][data["METHOD"]][data["CHUNK"]] = []
      if float(data["VALUE"]) > max_redis:
          max_redis = float(data["VALUE"])
      permutations_redis[row[0]][data["METHOD"]][data["CHUNK"]].append(
        float(data["VALUE"])
      )
  
  x_1 = []
  y_1 = []
  x_2 = []
  y_2 = []
  x_3 = []
  y_3 = []
  colors_1 = []
  colors_2 = []
  colors_3 = []
  for i in permutations_redis.keys():
      for j in permutations_nginx.keys():
          #print(permutations_nginx[j])
          if check_equal_permutations(permutations_redis[i]['spec'], permutations_nginx[j]['spec']):
              if "GET" in permutations_redis[i] and "REQ" in permutations_nginx[j]:
                  is_2 = 0
                  is_three = 0
                  is_two = 0
                  for k in permutations_nginx[j]:
                      if "COMPARTMENT" in k and k != "NUM_COMPARTMENTS":
                          if permutations_nginx[j][k] == '3':
                              is_three = 1

                          if permutations_nginx[j][k] == '2':
                              is_two = 1


                  if is_three:
                      colors_3.append('b')
                      x_3.append(sum(permutations_redis[i]["GET"]["5"]) / (max_redis * len(permutations_redis[i]["GET"]["5"])))
                      y_3.append(sum(permutations_nginx[j]["REQ"]["5"]) / (max_nginx * len(permutations_nginx[j]["REQ"]["5"])))
                  else:
                      if is_two:
                        colors_2.append('g')
                        x_2.append(sum(permutations_redis[i]["GET"]["5"]) / (max_redis * len(permutations_redis[i]["GET"]["5"])))
                        y_2.append(sum(permutations_nginx[j]["REQ"]["5"]) / (max_nginx * len(permutations_nginx[j]["REQ"]["5"])))
                      else:
                        colors_1.append('k')
                        x_1.append(sum(permutations_redis[i]["GET"]["5"]) / (max_redis * len(permutations_redis[i]["GET"]["5"])))
                        y_1.append(sum(permutations_nginx[j]["REQ"]["5"]) / (max_nginx * len(permutations_nginx[j]["REQ"]["5"])))

                  #print("{} {}### {} {}".format(i,permutations_redis[i]["GET"]["5"],j,permutations_nginx[j]["REQ"]["5"]))
 
  plt.rcParams.update({'font.size': 13.5})
  fig, ax = plt.subplots(figsize=(7, 2))
  ax.scatter(x_1, y_1, c=colors_1, marker="o", label="1 compartment")
  ax.scatter(x_2, y_2, c=colors_2, marker="v", label="2 compartments")
  ax.scatter(x_3, y_3, c=colors_3, marker="p", label="3 compartments")
  ax.legend()
  ax.plot((0, 1), "#306BAC", linestyle='--')
  ax.set_xlim(0, 1)
  ax.set_ylim(0, 1)
  plt.grid(linestyle='--')
  plt.ylabel("Nginx norm. perf.")
  plt.xlabel("Redis normalized performance")
  plt.savefig("nginx-redis-scatter.svg", format="svg", bbox_inches="tight")
  plt.show()
if __name__ == "__main__":
  if len(sys.argv) < 2:
    print("Usage: ./plot.sh PERMUTATIONS_REDIS RESULTS_NGINX")
    sys.exit()
    
  permutations = collate(
    permutations_file_redis=sys.argv[1],
    permutations_file_nginx=sys.argv[2],
    results_file_redis=sys.argv[3],
    results_file_nginx=sys.argv[4],
    
  ) 

