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

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare-flexos
prepare-flexos:
	$(DOCKER) build -f $(WORKDIR)/flexos-microbenchmarks.dockerfile \
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-microbenchmarks $(WORKDIR)

linux-latency:
	git clone https://github.com/project-flexos/app-flexos-microbenchmarks.git
	mv app-flexos-microbenchmarks linux-latency

.PHONY: prepare-linux
prepare-linux: linux-latency
	make linux -C linux-latency

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
	$(GNUPLOT) $(WORKDIR)/dss.plot
	mv $(WORKDIR)/dss.svg $(PLOT-DSS)
	$(GNUPLOT) $(WORKDIR)/latency.plot
	mv $(WORKDIR)/latency.svg $(PLOT-LATENCY)

.PHONY: clean
clean:
	rm -rf results $(PLOT-LATENCY) $(PLOT-DSS) linux-benchmark

.PHONY: properclean
properclean: clean
	$(DOCKER) image rm -f flexos-microbenchmarks
	$(DOCKER) image prune
