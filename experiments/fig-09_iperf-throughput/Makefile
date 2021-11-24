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
		--security-opt seccomp:unconfined -ti flexos-iperf /root/run.sh

.PHONY: plot
plot:
	$(GNUPLOT) $(WORKDIR)/iperf.plot
	mv $(WORKDIR)/iperf.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf results $(PLOT)

.PHONY: properclean
properclean:
	$(DOCKER) image rm flexos-iperf
	$(DOCKER) image prune
	rm -rf results $(PLOT)

