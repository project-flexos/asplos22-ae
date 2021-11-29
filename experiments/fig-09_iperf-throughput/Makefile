#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)
PLOT_FORMAT ?= svg
PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

#
# Parameters
#
KRAFT_TOKEN ?=
# These should be contiguous on the same NUMA node
NOISOLED_CPU1 ?= 1
NOISOLED_CPU2 ?= 2
NOISOLED_CPU3 ?= 3
NOISOLED_CPU4 ?= 4
ISOLED_CPU1 ?= 5
ISOLED_CPU2 ?= 6
ISOLED_CPU3 ?= 7

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

.PHONY: prepare
prepare:
	$(DOCKER) build -f $(WORKDIR)/flexos-iperf.dockerfile \
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-iperf $(WORKDIR)

.PHONY: run
run:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-iperf \
		/root/run.sh $(ISOLED_CPU1) $(ISOLED_CPU2) $(ISOLED_CPU3) \
		$(NOISOLED_CPU1) $(NOISOLED_CPU2) $(NOISOLED_CPU3) $(NOISOLED_CPU4)

.PHONY: plot
plot:
	rm -rf $(PLOT)
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(GNUPLOT) /out/iperf.plot
	mv $(WORKDIR)/iperf.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf results $(PLOT)

.PHONY: properclean
properclean: clean
	$(DOCKER) image rm -f flexos-iperf
	$(DOCKER) image prune
