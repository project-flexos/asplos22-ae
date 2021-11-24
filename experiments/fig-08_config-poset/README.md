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
is comparable, while that of nodes on different paths is not.

## Generating the plot

As a prerequisite, you'll need to install graphviz, on Debian/Ubuntu systems:
```
sudo apt install graphviz
```

Then you can generate the graph with:
```
make plot
```
