# Configuration Poset for Redis

<img align="right" src="fig-08_config-poset.svg" width="300" />

| Estimated Runtime |
| ----------------- |
| N/A               |

## Overview

This plot corresponds to Figure 8 in the paper, that presents the
configurations partially ordered set (poset) for the Redis performance numbers
presented in Figure 6. Each node represents a configuration, and a directed
edge between nodes n1 and n2 indicates that the level of safety of n1 is
probabilistically superior to that of n2. The safety of nodes on the same path
is comparable, while that of nodes on different paths is not. The color of a
node is indicates the performance of the corresponding configuration, with
black being the fastest (1209.7k req/s on our machine) and white being the
slowest (264.6k req/s). The stars represnt the most secure configuration
with performance > 500k req/s.

## Generating the plot

As a prerequisite, you'll need to install graphviz, on Debian/Ubuntu systems:
```
sudo apt install graphviz
```

Then you can generate the graph with:
```
make plot
```

## Details about the plot's data

For the sake of simplicity the [graphviz plot script](poset.dot) hardcodes data
we gathered for the paper on our machine. A detailed version of the poset is
available in this [PDF file](additional-resources/detailed-view.pdf). It
contains for each configuration its description as well as the corresponding
performance. The legend explains the labelling of the configurations.

### Plotting new results

In order to plot the poset for new Redis performance
numbers that would be obtained through the scripts relating to
[Figure 6](../fig-06_nginx-redis-perm), one would need to edit in the
[plot script](poset.dot) the `fillcolor` for each configuration, i.e. each
line with a `tooltip` attribute identifying a configuration with the same
scheme as in the [detailed poset view](additional-resources/detailed-view.pdf).

The mapping of performance numbers to graphviz's hexadecimal color codes is
automated in this LibreOffice [spreadsheet](additional-resources/raw-data.ods).
One will need to enter Redis' performance numbers for each configuration in the
column entitled "Redis GET Throughput", and the last column on the left will
automatically compute the hexadecimal value that should be set for the
`fillcolor` attribute of the corresponding configuration in the graphviz
plot script.

