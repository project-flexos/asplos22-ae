#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)
PLOT_FORMAT ?= svg
PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

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
	rm -rf results $(PLOT)

