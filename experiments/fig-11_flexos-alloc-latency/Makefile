#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)/results
PLOT_FORMAT ?= svg
DSS-PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)
LATENCY-PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

#
# Parameters
#
KRAFT_TOKEN ?=
ISOLED_CPU ?= 5

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

.PHONY: prepare-linux
prepare-linux:
	git clone https://github.com/project-flexos/app-flexos-microbenchmarks.git
	mv app-flexos-microbenchmarks linux-latency
	make linux -C linux-latency

.PHONY: prepare
prepare: prepare-flexos prepare-linux

.PHONY: run-flexos
run-flexos:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-microbenchmarks /root/run.sh

.PHONY: run-linux
run-linux:
	mkdir -p $(RESULTS)
	taskset -c $(ISOLED_CPU) $(WORKDIR)/linux-latency/benchmark > $(RESULTS)/latency-linux.dat
	# TODO reformat output here, handle KPTI / NOKPTI

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
	$(DOCKER) image rm flexos-microbenchmarks
	$(DOCKER) image prune
