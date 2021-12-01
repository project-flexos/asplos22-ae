#
# Files and directories
#
WORKDIR ?= $(CURDIR)
RESULTS ?= $(WORKDIR)
PLOT_FORMAT ?= svg
PLOT ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)

REDIS_PERMS_CSV ?= $(WORKDIR)/../fig-06_nginx-redis-perm/apps/redis/permutations-3.csv
NGINX_PERMS_CSV ?= $(WORKDIR)/../fig-06_nginx-redis-perm/apps/nginx/permutations-3.csv
# Change to results/ to use your freshly run results
REDIS_RES_CSV ?= $(WORKDIR)/../fig-06_nginx-redis-perm/paperresults/nginx.csv
NGINX_RES_CSV ?= $(WORKDIR)/../fig-06_nginx-redis-perm/paperresults/nginx.csv

#
# Tools
#
SNAKE ?= python3

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
	$(DOCKER) run --rm -v $(WORKDIR):/out --privileged -ti \
		ghcr.io/project-flexos/flexos-ae-plot $(SNAKE) /out/plot_scatter.py \
		$(REDIS_PERMS_CSV) $(NGINX_PERMS_CSV) $(REDIS_RES_CSV) $(NGINX_RES_CSV)
	mv $(WORKDIR)/nginx-redis-scatter.svg $(PLOT)

.PHONY: clean
clean:
	rm -rf $(PLOT)

.PHONY: properclean
properclean: clean
	@-

