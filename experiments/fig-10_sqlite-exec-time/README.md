# SQLite Performance Comparison

<img align="right" src="../../plots/fig-10_sqlite-exec-time.svg" width="300" />

| Estimated Runtime |
| ----------------- |
| 0h 0m             |

## Overview

Time to perform 5000 INSERT queries with SQLite on Unikraft, FlexOS, Linux, SeL4
(with the Genode system), and CubicleOS. The isolation profile is shown on the x
axis (NONE: no isolation, MPK3: MPK with three compartments, EPT2: two
compartments with EPT, PT2/3: two/three compartments with page-table-based
isolation).