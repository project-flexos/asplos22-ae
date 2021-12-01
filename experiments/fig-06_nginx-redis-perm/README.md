# NGINX and Redis Performance Across Varying Compartmentalisation Permutations

<img src="../../plots/fig-06_nginx-redis-perm.svg" />

| Estimated Runtime |
| ----------------- |
| 0h 0m             |

## Overview

Redis (top) and Nginx (bottom) performance for a range of configurations.
Components are on the left. Software hardening can be enabled [●] or disabled
[○] for each component. The white/blue/red color indicates the compartment the
component is placed into. Isolation is achieved with MPK and DSS.

## Running & customisation

This figure has its targets mapped as part of the global `Makefile` system of
the FlexOS Project Artifact Evaluation (AE) repository for ASPLOS'22.  At a
high-level, you can run:

```bash
make prepare-fig-06
make run-fig-06
make plot-fig-06
```

...And the experiment will run.  However, more likely you wish to tune the
experiment to your needs.  There are a number of internal targets which can run
independently of the high-level `Makefile` ASPLOS'22 AE repo.  To get started,
clone this repository and `cd` into this directory:

```bash
git clone https://github.com/project-flexos/asplos-ae.git
cd asplos-ae/experiments/fig-06_nginx-redis-perm
```

The applications to be constructed are variable (note that adding new apps
requires reating a build environment for them.  See the repository's `support/`
folder for examples).  This means we can target them individually.  To run the
permutations for NGINX, for example, you can run:

```
make prepare-wayfinder-app-nginx
make run-wayfinder-app-nginx
```

The number of compartments is a global variable which can be via the variable
`NUM_COMPARTMENTS=n`.  By default and for the paper, this was set to `3` to
demonstrate a good range of permutations and variety whilst still being
comprehendable.  For example, if you wish to build only 2 compartments, try
as follows:

```
NUM_COMPARTMENTS=2 make prepare-wayfinder-app-nginx
NUM_COMPARTMENTS=2 make run-wayfinder-app-nginx
```

