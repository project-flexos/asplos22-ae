#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)
PLOT_FORMAT ?= svg
PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare
prepare:
	@-

.PHONY: run
run:
	@-

.PHONY: plot
plot:
	./plot.sh $(PLOT_FORMAT) $(PLOT)

.PHONY: clean
clean:
	rm -rf $(PLOT)

.PHONY: properclean
properclean:
	rm -rf $(PLOT)

