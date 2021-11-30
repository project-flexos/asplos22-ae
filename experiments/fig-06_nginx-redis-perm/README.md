# NGINX and Redis Performance Across Varying Compartmentalisation Permutations

<img align="right" src="../../plots/fig-06_nginx-redis-perm.svg" width="300" />

| Estimated prep. time | Estimated runtime |
| -------------------- | ----------------- |
| 0h 0m                | 0h 00m            |

## Overview

Redis (top) and Nginx (bottom) performance for a range of configurations.
Components are on the left. Software hardening can be enabled [●] or disabled
[○] for each component. The white/blue/red color indicates the compartment the
component is placed into. Isolation is achieved with MPK and DSS.
