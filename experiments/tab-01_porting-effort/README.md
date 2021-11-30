# Porting Effort

| Estimated prep. time | Estimated runtime |
| -------------------- | ----------------- |
| 0h 2m                | 0h 25m (manual)   |

| Libs/Apps             | Patch size | Shared variables |
| --------------------- | ---------- | ---------------- |
| lwip                  | +542/-275  | 23               |
| uksched + ukschedcoop | +48/-8     | 5                |
| ramfs + vfscore       | +148/-37   | 12               |
| uktime                | +10/-9     | 0                |
| redis                 | +279/-90   | 16               |
| nginx                 | +470/-85   | 36               |
| sqlite                | +199/-145  | 24               |
| iperf                 | +15/-14    | 4                |

## Overview

Porting effort: size of the patch (including automatic gate replacements),
number of shared variables.

### Measurement workflow

These measurements are manual, but rather simple. For each repository or
subsystem, perform a `git diff` with the last Unikraft commit, and count the
meaningful +/- lines. For the shared variables, grep for `whitelist` and count
occurences.

Note that some libraries (mm, lwip, vfscore) include patches that are
not part of FlexOS but not yet merged into the Unikraft master at the time when
FlexOS was forked from Unikraft. We do not want to count these in the diff.

Here is a list of external, non-FlexOS patches applied:
- lwip: move `socket.c` to the glue code **[[link]](https://github.com/project-flexos/asplos22-ae/tree/main/experiments/tab-01_porting-effort/lwip-patches)**
- vfscore: CPIO support **[[link]](https://github.com/unikraft/eurosys21-artifacts/tree/master/support/patches-unikraft-eurosys21/cpio-series)**
- mm: page table support **[[link]](https://github.com/project-flexos/asplos22-ae/blob/main/experiments/fig-09_iperf-throughput/docker-data/unikraft-pagetable.patch)**

Note that the iperf app was developed for this paper; you can use the
[`unikraft-baseline`](https://github.com/project-flexos/lib-iperf/tree/unikraft-baseline)
branch as baseline for both the
[application](https://github.com/project-flexos/app-iperf) and the
[library](https://github.com/project-flexos/lib-iperf).

A similar situation affects sqlite; you can use [this unmodified
application](https://github.com/project-flexos/asplos22-ae/blob/main/experiments/fig-10_sqlite-exec-time/docker-data/main.c)
as baseline.

In order to simply the operation, we provide a simple docker container that
clones all relevant repositories into `/root/flexos`. You can build it with
`make prepare` and bash it with `make run`. The current directory is mounted in
`/out` in order to ease the sharing of results with the host.
