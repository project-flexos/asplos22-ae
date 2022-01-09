#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)/results
PLOT_FORMAT ?= svg
PLOT-DSS ?= $(WORKDIR)/$(notdir $(WORKDIR))-a.$(PLOT_FORMAT)
PLOT-LATENCY ?= $(WORKDIR)/$(notdir $(WORKDIR))-b.$(PLOT_FORMAT)

#
# Parameters
#
KRAFT_TOKEN ?=
ISOLED_CPU1 ?= 5
ISOLED_CPU2 ?= 6

#
# Tools
#
GNUPLOT ?= gnuplot
DOCKER ?= docker
TIME ?= /usr/bin/time

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare-flexos
prepare-flexos:
	$(TIME) $(DOCKER) build -f $(WORKDIR)/flexos-microbenchmarks.dockerfile \
		--build-arg GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-microbenchmarks $(WORKDIR)

linux-latency:
	git clone https://github.com/project-flexos/app-flexos-microbenchmarks.git
	mv app-flexos-microbenchmarks linux-latency

.PHONY: prepare-linux
prepare-linux: linux-latency
	$(TIME) make linux -C linux-latency

.PHONY: prepare
prepare: prepare-flexos prepare-linux

.PHONY: run-flexos
run-flexos:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-microbenchmarks \
		/root/run.sh $(ISOLED_CPU1) $(ISOLED_CPU2)

.PHONY: run-linux
run-linux:
	mkdir -p $(RESULTS)
	$(WORKDIR)/tools/benchmark_linux.sh $(RESULTS) $(WORKDIR)/linux-latency $(ISOLED_CPU1)

.PHONY: run
run: run-flexos run-linux

.PHONY: plot
plot:
	rm -rf $(PLOT-LATENCY) $(PLOT-DSS)
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(GNUPLOT) /out/dss.plot
	mv $(WORKDIR)/dss.svg $(PLOT-DSS)
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(GNUPLOT) /out/latency.plot
	mv $(WORKDIR)/latency.svg $(PLOT-LATENCY)

.PHONY: clean
clean:
	rm -rf results $(PLOT-LATENCY) $(PLOT-DSS) linux-benchmark

.PHONY: properclean
properclean: clean
	$(DOCKER) image rm -f flexos-microbenchmarks
	$(DOCKER) image prune
