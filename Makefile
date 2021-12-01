#
# Directories
#
WORKDIR ?= $(CURDIR)

#
# Parameters
#
KRAFT_TOKEN ?= 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

#
# General configuration
#
REG     ?= ghcr.io
ORG     ?= project-flexos
EXPS    ?= fig-06_nginx-redis-perm \
           fig-07_nginx-redis-normalized \
           fig-08_config-poset \
           fig-09_iperf-throughput \
           fig-10_sqlite-exec-time \
           fig-11_flexos-alloc-latency \
           tab-01_porting-effort
IMAGES  ?= flexos-base \
           nginx \
           redis \
           flexos-ae-plot \
           flexos-ae-base
TARGETS ?= prepare \
           run \
           plot \
           clean \
           properclean

ifeq ($(KRAFT_TOKEN),)
define ERROR_MISSING_TOKEN


<!> Missing `KRAFT_TOKEN` environmental variable <!>

This variable is used to connect the command-line utility `kraft` to the GitHub
API and download additional Unikraft repositories.  To generate a new token,
go to https://github.com/settings/tokens/new and select permission:

  - repo:public_repo

Once you have generated this token, simply export it in your command-line, like
so:

  $$ export KRAFT_TOKEN=ghp_...

Once this is done, please re-run your command:

  $$ $(MAKE) $(MAKECMDGOALS)


endef
  $(error $(ERROR_MISSING_TOKEN))
endif

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
CURL ?= curl

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
		--build-arg UK_KRAFT_GITHUB_TOKEN="$(KRAFT_TOKEN)" \
		--file $(WORKDIR)/support/dockerfiles/Dockerfile.$(@:docker-%=%) \
		$(WORKDIR)/support

# Prepare the final Zenodo archive
zenodo:
	mkdir -p $(WORKDIR)/repositories
	# clone all repos in the flexos organization
	cd $(WORKDIR)/repositories && \
		$(CURL) -s https://github.com:@api.github.com/orgs/${ORG}/repos?per_page=200 | \
		jq .[].ssh_url | xargs -n 1 git clone
	tar -czf $(WORKDIR)/../flexos-asplos22-ae.tar.gz $(WORKDIR)

dependencies:
	apt install time
