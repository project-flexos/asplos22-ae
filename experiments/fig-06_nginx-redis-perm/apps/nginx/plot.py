#!/usr/bin/python3

import os
import sys
import csv
import pprint
import numpy as np
import matplotlib as mpl
import matplotlib.pyplot as plt
from collections import OrderedDict
from matplotlib.colors import LogNorm
# mpl.use('TkAgg')

pp = pprint.PrettyPrinter(indent=4)

THROUGHPUT = 'throughput'
MEAN_KEY = 'mean'
MEDIAN_KEY = 'median'
AMAX_KEY = 'amax'
AMIN_KEY = 'amin'

ALL = '__ALL'

SMALL_SIZE = 12
MEDIUM_SIZE = 14
LARGE_SIZE = 18
BIGGER_SIZE = 24
KBYTES = 1024.0

PATTERNS = ('-', '+', 'x', '\\', '.')

# SYMBOL = ["◯", "⬤"]
SYMBOL = [r'$\circ$', r'$\bullet$']

COLORS = [
  "#ffffff",  # white
  '#91c6e7',  # blue
  '#d18282',  # red
  '#ddcae3',  # lavender
  '#a2d9d1',  # thyme
  '#ededed',  # gray
  '#fff3cd',  # yellow
  '#91c6e7',  # light blue
  '#618c84',  # dark green
  '#49687c',  # dark blue
  '#7c4f4f',  # dark yellow
]

def collate(permutations_file=None, results_file=None):
  if not os.path.isfile(permutations_file):
    print("Cannot find: %s" % permutations_file)
    sys.exit(1)

  if not os.path.isfile(results_file):
    print("Cannot find: %s" % results_file)
    sys.exit(1)

  permutations = {}

  with open(permutations_file, 'r') as csvfile:
    print("Processing %s..." % permutations_file)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      permutations[row[0]] = (dict(zip(cols[1:], row[1:])))

  with open(results_file, 'r') as csvfile:
    print("Processing %s..." % results_file)
    csvdata = csv.reader(csvfile, delimiter=",")
    cols = next(csvdata)
    for row in csvdata:
      data = dict(zip(cols[1:], row[1:]))

      if row[0] not in permutations:
        print("Missing result from permutation: %s" % row[0])
        continue

      if data["METHOD"] not in permutations[row[0]]:
        permutations[row[0]][data["METHOD"]] = {}

      if data["CHUNK"] not in permutations[row[0]][data["METHOD"]]:
        permutations[row[0]][data["METHOD"]][data["CHUNK"]] = []

      permutations[row[0]][data["METHOD"]][data["CHUNK"]].append(
        float(data["VALUE"])
      )

  for taskid in permutations:
    for action in ['REQ']:
      if action in permutations[taskid]:
        data = permutations[taskid][action]

        all_throughput = []

        for chunk in data:
          throughput = {
            MEAN_KEY: np.average(data[chunk]),
            MEDIAN_KEY: np.median(data[chunk]),
            AMAX_KEY: np.amax(data[chunk]),
            AMIN_KEY: np.amin(data[chunk])
          }

          all_throughput.extend(data[chunk])
          permutations[taskid][action][chunk] = throughput

        permutations[taskid][action][ALL] = {
          MEAN_KEY: np.average(all_throughput),
          MEDIAN_KEY: np.median(all_throughput),
          AMAX_KEY: np.amax(all_throughput),
          AMIN_KEY: np.amin(all_throughput)
        }

  libraries = {}
  for col in permutations[list(permutations.keys())[0]]:
    if col.startswith("LIB") and col.endswith("_COMPARTMENT"):
      library = col[:-12]
      libraries[library[3:].lower().replace("_", "-")] = library

  # HACK: Remove invalid permutations.  These shouldn't even be built, but
  # here we are.
  valid_permutations = {}
  for taskid in permutations:
    data = permutations[taskid]
    if int(data['NUM_COMPARTMENTS']) != 3:
      continue

    used_comps = []

    for library in libraries:
      comp_key = "%s_COMPARTMENT" % libraries[library]
      used_comps.append(int(data[comp_key]))

    if (int(data["LIBLWIP_COMPARTMENT"]) > 2):
      continue

    if 2 not in used_comps and 3 in used_comps:
      continue

    valid_permutations[taskid] = data

  return valid_permutations


def rotate_matrix(m):
    return [[m[j][i] for j in range(len(m))] for i in range(len(m[0])-1,-1,-1)]


def common_style(plt):
  plt.style.use('classic')
  plt.tight_layout()

  plt.rcParams['text.usetex'] = False
  plt.rc('pdf', fonttype=42)
  plt.rc('font',**{
    'family':'sans-serif',
    'sans-serif':['Helvetica']}
  )
  plt.rc('text', usetex=True)

  # plt.rcParams['font.sans-serif'] = "Comic Sans MS"
  plt.rcParams['font.family'] = "sans-serif"

  plt.rc('font', size=MEDIUM_SIZE)         # controls default text sizes
  plt.rc('axes', titlesize=MEDIUM_SIZE)    # fontsize of the axes title
  plt.rc('axes', labelsize=LARGE_SIZE)     # fontsize of the x and y labels
  plt.rc('xtick', labelsize=LARGE_SIZE)   # fontsize of the tick labels
  plt.rc('ytick', labelsize=MEDIUM_SIZE)   # fontsize of the tick labels
  plt.rc('legend', fontsize=MEDIUM_SIZE)   # legend fontsize
  # plt.rc('figure', titlesize=BIGGER_SIZE, titleweight='bold')  # fontsize of the figure title


def plot(permutations={}, output_file=None):
  if len(permutations.keys()) == 0:
    print("No data ):")
    return

  # Get a list of all libraries
  libraries = {}
  for col in permutations[list(permutations.keys())[0]]:
    if col.startswith("LIB") and col.endswith("_COMPARTMENT"):
      library = col[:-12]
      if library == "LIBTLSF" or library == "LIBPTHREAD_EMBEDDED":
        continue
      libraries[library[3:].lower().replace("_", "-")] = library

  libraries = {
    'nginx': 'LIBNGINX',
    'newlib': 'LIBNEWLIB',
    'uksched': 'LIBUKSCHED',
    'lwip': 'LIBLWIP',
  }


  print("Sorting the data and re-createing the permutations object...")
  permutations_perf = {}
  for taskid in permutations:
    if "REQ" in permutations[taskid]:
      permutations_perf[taskid] = permutations[taskid]["REQ"]["0"][MEAN_KEY]
    else:
      permutations_perf[taskid] = 0

  permutations_perf = {
    k: v for k, v in sorted(permutations_perf.items(), key=lambda item: item[1])
  }


  permutations_sorted = OrderedDict()
  for taskid in permutations_perf:
    permutations_sorted[taskid] = permutations[taskid]

  # Create a matrix of the boolean use of SPI per library and a separate matrix
  # containing the ID of the compartment
  sfi_matrix = []
  comp_matrix = []
  get_matrix = []
  set_matrix = []
  trust_scenario_array = []

  get_min_matrix = []
  get_max_matrix = []
  set_min_matrix = []
  set_max_matrix = []
  taskids = []

  chunk = '0'
  rules = {}
  k = 0

  print("Collating data in to plottable matrices...")
  for taskid in permutations_sorted:
    sfi_usage = []
    comp_usage = []
    permutation = permutations[taskid]
    colors = ""
    taskids.append(taskid)

    for library in list(libraries.keys())[::-1]:
      sfi_key = "%s_SFI" % libraries[library]
      sfi_usage.append(SYMBOL[1] if permutation[sfi_key] == "y" else SYMBOL[0])

      comp_key = "%s_COMPARTMENT" % libraries[library]
      comp_usage.append(COLORS[int(permutation[comp_key]) - 1])
      colors = colors + str(COLORS[int(permutation[comp_key]) - 1])
    if colors not in rules:
      rules[colors] = k
      k = k + 1
    trust_scenario_array.append(rules[colors])

    sfi_matrix.append(sfi_usage)
    comp_matrix.append(comp_usage)

    _get = 0
    _get_min = 0
    _get_max = 0
    if "REQ" in permutation:
      _get = permutation["REQ"][chunk][MEAN_KEY]
      _get_min = permutation["REQ"][chunk][AMIN_KEY]
      _get_min = _get - _get_min
      _get_max = permutation["REQ"][chunk][AMAX_KEY]
      _get_max = _get_max - _get

    get_matrix.append(_get)
    get_min_matrix.append(_get_min)
    get_max_matrix.append(_get_max)

  for i, taskid in enumerate(taskids):
    if get_matrix[i] == 0:
      print("WARNING! TASKID=%s has zero value!" % taskid)

  print("Rotating data...")
  sfi_matrix = rotate_matrix(sfi_matrix)
  comp_matrix = rotate_matrix(comp_matrix)
  labels = list(permutations_sorted.keys())
  x = np.arange(len(labels))  # the label locations

  # chart_min = permutations_sorted[labels[0]]['GET'][ALL][AMIN_KEY] / 1000
  # chart_max = permutations_sorted[labels[-1]]['GET'][ALL][AMAX_KEY] / 1000
  chart_min = 10000
  chart_max = 230000

  print("Setting up figure...")

  # Setup matplotlib axis
  common_style(plt)

  fig = plt.figure(figsize=(14, 2.5))
  ax1 = fig.add_subplot(1,1,1)
  ax1.set_ylabel(r'Average http' + "\n" + r'request/s (x1000)',
    fontsize=SMALL_SIZE,
    horizontalalignment='center',
    multialignment='center'
  )
  ax1.grid(which='major', axis='y', linestyle=':', alpha=0.5, zorder=0)
  # ax1.set_yscale('log')
  # ax_yticks = np.arange(
  #   chart_min,
  #   chart_max + 1,
  #   step=100
  # )
  # ax1.set_yticks(ax_yticks, minor=False)
  # ax_yticks_labels = list(ax_yticks)
  # ax_yticks_labels[0] = ""
  # ax1.set_yticklabels(ax_yticks_labels)
  ax1.set_ylim(chart_min, chart_max)

  # ax1.hlines(y, xmin, xmax,
  # ax1.axhline(y=300, color='r', linestyle='-')

  # Add some text for labels, title and custom x-axis tick labels, etc.
  ax1.set_xticks(x)
  ax1.set_xticklabels(labels)
  # ax1.legend()

  width = 0.5  # the width of the bars

  print("Adding bars...")

  # Plot bar graphs
  ax1.bar(x, get_matrix, width,
    label='REQ',
    fill=False,
    yerr=[get_min_matrix, get_max_matrix],
    # linewidth=1,
  )

  print("Adding text above bars...")
  for i, val in enumerate(get_matrix):
    # permutations_text.append(
    #   "%3.1f" % (permutations_perf[taskid] / 1000)

    # ax1.text(i, val + ((val/10) * 3), "%3.1fk" % (val/1000),
    ax1.text(i, val + 20000, "%3.1fk" % (val/1000),
      ha='center',
      # va='bottom',
      fontsize=SMALL_SIZE - 3,
      # linespacing=0,
      # zorder=2,
      # bbox=dict(pad=0, facecolor='white', linewidth=0),
      rotation='vertical'
    )


  print("Setting margins...")

  # Center-align the bars so they match up with the table
  plt.margins((1 - width) / (2 * len(labels)), 0.1)

  print("Writing table...")

  # Add a table at the bottom of the axes
  print("Appending the trust model to the table...")

  the_table = ax1.table(
    cellText=sfi_matrix,
    rowLabels=list(libraries.keys()),
    cellColours=comp_matrix,
    loc='bottom',
    cellLoc='center',
    fontsize=BIGGER_SIZE,
  )

  the_table.scale(1, 1.6) # table cell padding
  the_table.auto_set_font_size(False)
  the_table.set_fontsize(MEDIUM_SIZE)

  # Hack to decrease the row label size
  for key, cell in the_table.get_celld().items():
    if key[1] == -1:
      cell.set_fontsize(SMALL_SIZE - 2)

  # Adjust layout to make room for the table:
  # plt.subplots_adjust(top=0, bottom=0.5) # left=-1, right=-.8) # bottom=0.5)

  # plt.legend(loc="upper left")
  plt.xticks([])
  # plt.title('')

  print("Squeezing layout...")
  fig.tight_layout()

  print("Saving plot to %s..." % output_file)
  fig.savefig(output_file)

  print("Done!")


if __name__ == "__main__":
  if len(sys.argv) < 4:
    print("Usage: ./plot.sh PERMUTATIONS_FILE RESULTS_FILE OUTPUT_FILE")
    sys.exit()

  permutations = collate(
    permutations_file=sys.argv[1],
    results_file=sys.argv[2]
  )

  plot(
    permutations=permutations,
    output_file=sys.argv[3]
  )
