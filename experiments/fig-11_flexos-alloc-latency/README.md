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
parameters. You can achieve this via the following commands:

```bash
vim /etc/default/grub # add pti=off to GRUB_CMDLINE_LINUX_DEFAULT
update-grub
reboot
cat /proc/cmdline # make sure that it contains pti=off
```

Re-enabling KPTI can be done with inverse steps.

Note to ASPLOS'22 AE reviewers: disabling KPTI will affect all other
measurements, not only Linux for this figure. Make sure to re-enable KPTI as
soon as you are done with this measurement. Cooperation among reviewers for
this benchmark is recommended.
