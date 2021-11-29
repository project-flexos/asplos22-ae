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
SNAKE ?= python3
DOCKER ?= docker

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare
prepare:
	$(DOCKER) build -f $(WORKDIR)/flexos-porting.dockerfile \
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--tag flexos-porting $(WORKDIR)

.PHONY: run
run:
	mkdir results
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged \
		--security-opt seccomp:unconfined -ti flexos-porting /root/run.sh

.PHONY: plot
plot:
	$(SNAKE) $(WORKDIR)/plot.py --data $(RESULTS) --output $(PLOT)

.PHONY: clean
clean:
	rm -rf results

.PHONY: properclean
properclean:
	$(DOCKER) image rm -f flexos-porting
	$(DOCKER) image prune

