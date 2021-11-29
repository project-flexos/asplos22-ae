# iPerf throughput

<img align="right" src="fig-09_iperf-throughput.svg" width="300" />

| Estimated Runtime |
| ----------------- |
| 0h 0m             |

## Overview

Network throughput (iPerf) with Unikraft (baseline), FlexOS w/o isolation, with
2 compartments backed by MPK (-_light_ = shared call stacks, -_dss_ = protected
and DSS) and EPT.

## Troubleshooting

- **Problem**: EPT measurements show very low performance, not achieving more
  than a few 100Mb/s.

  **Solution**: This is typically due to pinning issues. EPT measurements are not
  all pinned like MPK measurements for technical reasons, and they use 4
  non-isolated cores. If these cores are improperly set (different NUMA node
  than isolated ones, noise on them), this might result in drastic loss of
  performance.
