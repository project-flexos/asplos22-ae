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
DOCKER ?= docker
TIME ?= /usr/bin/time

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare
prepare:
	$(TIME) $(DOCKER) build -f $(WORKDIR)/flexos-porting.dockerfile \
		--build-arg GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-porting $(WORKDIR)

.PHONY: run
run:
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-porting bash

.PHONY: plot
plot:
	@-

.PHONY: clean
clean:
	@-

.PHONY: properclean
properclean:
	$(DOCKER) image rm -f flexos-porting
	$(DOCKER) image prune -f
