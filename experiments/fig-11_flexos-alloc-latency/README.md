# FlexOS Latency Microbenchmarks

<img align="right" src="../../plots/fig-11_flexos-alloc-latency.svg" width="300" />

| Estimated Runtime |
| ----------------- |
| 0h 0m             |

## Overview

Gate and allocation latency microbenchmarks. FlexOS is compared with Linux
(with and without KPTI).

### :warning: Measurements without KPTI

Measurements without KPTI require a reboot with different kernel command line
parameters. You can achieve this using `toggle-kpti.sh on`. Once you are done
with the measurement, we recommend that you immediately run `toggle-kpti.sh
off` to reset the machine to its initial state.

Note (especially to ASPLOS'22 AE reviewers): disabling KPTI will affect all
other measurements, not only Linux for this figure. Make sure to re-enable KPTI
as soon as you are done with this measurement. Cooperation among reviewers for
this benchmark is recommended.
