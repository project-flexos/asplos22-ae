#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)
PLOT_FORMAT ?= svg
PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

FIG6DIR ?= $(WORKDIR)/../fig-06_nginx-redis-perm/
REDIS_PERMS_CSV ?= apps/redis/permutations-3.csv
NGINX_PERMS_CSV ?= apps/nginx/permutations-3.csv
# Change to results/ to use your freshly run results
REDIS_RES_CSV ?= paperresults/nginx.csv
NGINX_RES_CSV ?= paperresults/nginx.csv

#
# Tools
#
SNAKE ?= /usr/bin/python3
DOCKER ?= docker

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
	rm -rf $(PLOT)
	$(DOCKER) run --rm -v $(WORKDIR):/out -v $(FIG6DIR):/fig6 --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(SNAKE) /out/plot_scatter.py \
		/fig6/$(REDIS_PERMS_CSV) /fig6/$(NGINX_PERMS_CSV) \
		/fig6/$(REDIS_RES_CSV) /fig6/$(NGINX_RES_CSV)
	mv $(WORKDIR)/nginx-redis-scatter.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf $(PLOT)

.PHONY: properclean
properclean: clean
	@-

