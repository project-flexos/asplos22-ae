# FlexOS ASPLOS'22 Artifact Evaluation

This repository contains the artifacts, including experiments and graphs, for
the paper:

### FlexOS: Towards Flexible OS Isolation

 > **Abstract**:  At design time, modern operating systems are locked in a
> specific safety and isolation strategy that mixes one or more
> hardware/software protection mechanisms (e.g. user/kernel separation);
> revisiting these choices after deployment requires a major refactoring effort.
> This rigid approach shows its limits given the wide variety of modern
> applications' safety/performance requirements, when new hardware isolation
> mechanisms are rolled out, or when existing ones break.
> 
> We present FlexOS, a novel OS allowing users to easily specialize the
> safety and isolation strategy of an OS at compilation/deployment time
> instead of design time. This modular LibOS is composed of fine-grained
> components that can be isolated via a range of hardware protection mechanisms
> with various data sharing strategies and additional software hardening. The
> OS ships with an exploration technique helping the user navigate the vast
> safety/performance design space it unlocks. We implement a prototype of the
> system and demonstrate, for several applications (Redis/Nginx/SQLite),
> FlexOS’ vast configuration space as well as the efficiency of the
> exploration technique: we evaluate 80 FlexOS configurations for Redis and
> show how that space can be probabilistically subset to the 5 safest ones under
> a given performance budget. We also show that, under equivalent
> configurations, FlexOS performs similarly or better than several
> baselines/competitors.


If at all possible, please read through this entire document before installing
or running experiments.

## 1. Experiments

The paper comes with 11 figures and 1 tables worth of experiments (although not
all of them have experimental results, e.g.,  Figure 2 is an architecture
diagram).  Each experiment and the relevant scripts to generate the data and
subsequent plots are included in this repository.  We expect the results
generated from this artifact to match one-to-one with the results in the paper,
given that we used this artifact/scripts to actually generate all figures in the
paper.

Each figure, table and corresponding experiment are listed below:

| Figure                                                  |                                                                   | Description                                                                                                                                                                                                                                                                                                                     | Est. runtime |
| ------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| [`fig_06`](/experiments/fig_06_nginx-redis-perm/)       | <img src="plots/fig_06_nginx-redis-perm.svg" width="200" />       | Redis (top) and Nginx (bottom) performance for a range of configurations. Components are on the left. Software hardening can be enabled [•] or disabled [◦] for each component. The white/blue/red color indicates the compartment the component is placed into. Isolation is achieved with MPK and DSS.                        | 0h 0m        |
| [`fig_07`](/experiments/fig_07_nginx-redis-normalized/) | <img src="plots/fig_07_nginx-redis-normalized.svg" width="200" /> | Nginx versus Redis normalized performance.                                                                                                                                                                                                                                                                                      | 0h 0m        |
| [`fig_08`](/experiments/fig_08_config-posit/)           | <img src="plots/fig_08_config-posit.svg" width="200" />           | Configurations poset for the Redis numbers (Figure 6).  Stars are the most secure configs. with perf. >= 500k req/s.                                                                                                                                                                                                            | 0h 0m        |
| [`fig_09`](/experiments/fig_09_iperf-throughput/)       | <img src="plots/fig_09_iperf-throughput.svg" width="200" />       | NW throughput (iPerf) with Unikraft (baseline), FlexOS w/o isolation, with 2 compartments backed by MPK (-_light_ = shared call stacks, -_dss_ = protected and DSS) and EPT.                                                                                                                                                    | 0h 0m        |
| [`fig_10`](/experiments/fig_10_sqlite-exec-time/)       | <img src="plots/fig_10_sqlite-exec-time.svg" width="200" />       | Time to perform 5000 INSERT queries with SQLite on Unikraft, FlexOS, Linux, SeL4 (with the Genode system), and CubicleOS. The isolation profile is shown on the x axis (NONE: no isolation, MPK3: MPK with three compartments, EPT2: two compartments with EPT, PT2/3: two/three compartments with page-table-based isolation). | 0h 0m        |
| [`fig_11`](/experiments/fig_11_flexos-alloc-latency/)   | <img src="plots/fig_11_flexos-alloc-latency.svg" width="200" />   | FlexOS latency microbenchmarks.                                                                                                                                                                                                                                                                                                 | 0h 0m        |
| [`tab_01`](/experiments/fig_01_porting-effort/)         | <img src="plots/tab_01_porting-effort.svg" width="200" />         | Porting effort: size of the patch (including automatic gate replacements), number of shared variables.                                                                                                                                                                                                                          | 0h 0m        |

## 2. Repository structure

We have organised this repository as follows:

 * `experiments/` - All experiments are listed in this directory.  Each
   sub-directory is named with the figure number along with a short description
   of the experiment (e.g., `fig_06_nginx-redis-perm`).  In addition, each
   experiment sub-directory has a corresponding `README.md` which explains in
   more detail how the experiment works and how to run it.  Along with this,
   each sub-directory also comes with a `Makefile` with the following targets:
    - `prepare`: prepares the experiment, by usually downloading and building
      relevant images, tools, and auxiliary services necessary for running the
      experiment.
    - `run`: runs the experiment.
    - `plot`: produces the figure or table.  All plots are automatically saved
      into the [`plots/`](/plots) directory.
    - `clean`: removes intermediate build files.
 * `plots/` - Contains all resulting figures seen in the paper.
