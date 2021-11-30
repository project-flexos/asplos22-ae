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

.PHONY: prepare
prepare:
	$(TIME) $(DOCKER) build -f $(WORKDIR)/flexos-sqlite.dockerfile \
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-sqlite $(WORKDIR)

.PHONY: run
run:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-sqlite \
		/root/run.sh $(ISOLED_CPU1) $(ISOLED_CPU2)

.PHONY: plot
plot:
	rm -rf $(PLOT)
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(GNUPLOT) /out/sqlite.plot
	mv $(WORKDIR)/sqlite.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf results $(PLOT)

.PHONY: properclean
properclean: clean
	$(DOCKER) image rm -f flexos-sqlite
	$(DOCKER) image prune
