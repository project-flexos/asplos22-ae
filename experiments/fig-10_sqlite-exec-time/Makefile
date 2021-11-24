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
	$(DOCKER) build -f $(WORKDIR)/flexos-sqlite.dockerfile \
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-sqlite $(WORKDIR)

.PHONY: run
run:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-sqlite /root/run.sh

.PHONY: plot
plot:
	$(GNUPLOT) $(WORKDIR)/sqlite.plot
	mv $(WORKDIR)/sqlite.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf results $(PLOT)

.PHONY: properclean
properclean:
	$(DOCKER) image rm flexos-sqlite
	$(DOCKER) image prune
	rm -rf results $(PLOT)
