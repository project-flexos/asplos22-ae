#
# Directories
#
WORKDIR ?= $(CURDIR)

#
# General configuration
#
REG     ?= ghcr.io
ORG     ?= ukflexos
EXPS    ?= fig-06_nginx-redis-perm \
           fig-07_nginx-redis-normalized \
           fig-08_config-poset \
           fig-09_iperf-throughput \
           fig-10_sqlite-exec-time \
           fig-11_flexos-alloc-latency \
           tab-01_porting-effort
IMAGES  ?= flexos-base \
           nginx \
           redis
TARGETS ?= prepare \
           run \
           plot \
           clean \
           properclean

#
# Utility vars
#
# Prefix each docker image with `docker-` so it has a unique phony target
DIMAGES := $(addprefix docker-,$(IMAGES))
Q       ?= @

#
# Tools
#
DOCKER  ?= docker

#
# Find shortname for experiment
#
# Params:
#   $1: The canonical name of the experiment, e.g. `fig-XX_short-desc`
#   $2: The desired returning element, 1 for `fig-XX` and 2 for `short-desc`
#
underscore  = $(word $(2),$(subst _, ,$(1)))

#
# Create a new experiment target
#
# Params:
#   $1: The common API target, e.g. `prepare` 
#   $2: The canonical name of the experiment, e.g. `fig-XX_short-name`
#
define create-exp-target
.PHONY: $(1)
$(1): $(1)-$(2)

.PHONY: $(2)
$(2): $(1)

.PHONY: $(1)-$(2)
$$(call underscore,$(2),1): $(1)-$(2)
$(1)-$$(call underscore,$(2),1): $(1)-$(2)
$(1)-$(2):
	$(Q)$(MAKE) -C $(WORKDIR)/experiments/$(2) $(1)
endef

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare
prepare: docker

# Iterate over all experiments and all targets and provide an entrypoint for
# each, e.g. `prepare-fig-XX_short-desc` and `prepare-fig-XX`.
$(foreach EXP,$(EXPS), \
	$(foreach TARGET,$(TARGETS),$(eval $(call create-exp-target,$(TARGET),$(EXP))) \
))

.PHONY: docker
docker: $(DIMAGES)

.PHONY: $(DIMAGES)
$(DIMAGES): TAG ?= latest
$(DIMAGES):
	$(Q)$(DOCKER) build \
		--tag $(REG)/$(ORG)/$(@:docker-%=%):$(TAG) \
		--file $(WORKDIR)/support/dockerfiles/Dockerfile.$(@:docker-%=%) \
		$(WORKDIR)/support/dockerfiles
