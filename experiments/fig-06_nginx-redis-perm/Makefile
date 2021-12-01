#
# Files and directories
#
REG              ?= ghcr.io
ORG              ?= project-flexos
WORKDIR          ?= $(CURDIR)
RESULTSDIR       ?= $(WORKDIR)/results
TMPDIR           ?= /tmp/$(notdir $(WORKDIR))
APPSDIR          ?= $(WORKDIR)/apps
PLOT_FORMAT      ?= svg
PLOT             ?= $(WORKDIR)/$(notdir $(WORKDIR)).$(PLOT_FORMAT)
TAG              ?= latest
Q                ?= @

#
# Experiment variables
#
WAYFINDER_CORES  ?= 1,2
# HOST_CORES       ?= 3-19
HOST_CORES       ?= 13-30
APPS             ?= nginx \
                    redis
NUM_COMPARTMENTS ?= 3
TEST_ITERATIONS  ?= 1

#
# Tools
#
SNAKE            ?= python3
WGET             ?= wget
APT              ?= apt
MKDIR            ?= mkdir -p
WAYFINDER        ?= wayfinder
RM               ?= rm
TASKSET          ?= taskset
TOTALCPUS        ?= $(lscpu | grep '^CPU(s):' | awk '{ print $$2 }')
YTT              ?= ytt
# Tools
DOCKER           ?= docker
DOCKER_RUN       ?= $(DOCKER) run --rm $(2) \
                      $(foreach E, $(shell printenv), -e "$(E)") \
                      --entrypoint "" \
                      -w /workspace \
                      -v $(WORKDIR):/workspace \
                      $(REG)/$(ORG)/$(1):$(TAG) \
                        $(3)
CAT              ?= cat
JQ               ?= jq
GCC              ?= gcc

#
# Targets
#
.PHONY: all
all: prepare run plot

.PHONY: prepare
prepare: install-wayfinder
prepare: prepare-templates
prepare: $(WORKDIR)/apps/redis/redis-benchmark
	$(APT) update
	$(APT) install --no-install-recommends \
		bridge-utils \
		net-tools \
		socat \
		uuid-runtime \
		wrk \
		redis-tools \
		jq

# If run with DOCKER= or within a container, unset DOCKER_RUN so all commands
# are not proxied via docker container.
ifeq ($(DOCKER),)
DOCKER_RUN    :=
else ifneq ($(wildcard /.dockerenv),)
DOCKER_RUN    :=
endif
.DOCKER_PROXY :=
ifneq ($(DOCKER_RUN),)
.DOCKER_PROXY := docker-proxy-
prepare-wayfinder-app-%:
	$(info Running target via $(REG)/$(ORG)/flexos-base:$(TAG)...)
	$(Q)$(call DOCKER_RUN,flexos-base,,$(MAKE) $@)
plot-app-%:
	$(info Running target via $(REG)/$(ORG)/flexos-ae-base:$(TAG)...)
	$(Q)$(call DOCKER_RUN,flexos-ae-base,,$(MAKE) $@)
endif

#
# Create preparation step for an application
#
# Params:
#   $1: The application name
#
define prepare-wayfinder-app

# This is an entry which is used to generate a job file to be used by Wayfinder.
# The job file creates all the possible permutations which will result in a
# unique unikernel binary image.
.PHONY: $$(.DOCKER_PROXY)prepare-wayfinder-app-$(1)
$$(.DOCKER_PROXY)prepare-wayfinder-app-$(1): $$(APPSDIR)/$(1)/wayfinder-jobs/$$(NUM_COMPARTMENTS).yaml
$$(APPSDIR)/$(1)/wayfinder-jobs/$$(NUM_COMPARTMENTS).yaml:
	$$(YTT) \
		--data-value num_compartments=$$(NUM_COMPARTMENTS) \
		--file $$(APPSDIR)/$(1)/templates/wayfinder > $$(APPSDIR)/$(1)/wayfinder-jobs/$$(NUM_COMPARTMENTS).yaml

# Make the general preparation step have these dynamic entries as dependents
$$(.DOCKER_PROXY)prepare-templates: $$(.DOCKER_PROXY)prepare-wayfinder-app-$(1)

# Make the general run step have these dynamic entries as dependents
run-wayfinder: run-wayfinder-app-$(1)

# This is an entry which is used to create a unique run-entry for the app,
# allowing you to run a specific application (and thus its permutations).  We
# set the working directory (-w) on wayfinder within the /tmp folder, as this
# will significantly speed up builds.  Please ensure you have enough RAM or
# set an alternative path via:
#
#  $ make TMPDIR=/path/to/dir run-wayfinder
#
# Also, cores have been hard-coded, please adjust according to your machine, and
# again, set accordingly, e.g.:
#
#  $ make HOST_CORES="3,12,24" run-wayfinder
#
.PHONY: run-wayfinder-app-$(1)
run-wayfinder-app-$(1):
ifeq ($$(WAYFINDER_CORES),)
	$$(WAYFINDER) -v run \
		--cpu-sets $$(HOST_CORES) \
		-w $$(TMPDIR)/wayfinder-build-$(1)/ \
		$$(APPSDIR)/$(1)/wayfinder-jobs/$$(NUM_COMPARTMENTS).yaml
else
	$$(TASKSET) -c $$(WAYFINDER_CORES) \
	$$(WAYFINDER) -v run \
		--cpu-sets $$(HOST_CORES) \
		-w $$(TMPDIR)/wayfinder-build-$(1)/ \
		$$(APPSDIR)/$(1)/wayfinder-jobs/$$(NUM_COMPARTMENTS).yaml
endif

# Target to run the test script on all permutations
.PHONY: test-app-$(1)
test-app-$(1): $$(RESULTSDIR)
test-app-$(1): RESULTS ?= $$(RESULTSDIR)/$(1).csv
test-app-$(1): UNIKERNEL_INITRD ?= $$(APPSDIR)/$(1)/$(1).cpio
test-app-$(1):
	QEMU_GUEST=$$(WORKDIR)/support/qemu-guest \
	ITERATIONS=$$(TEST_ITERATIONS) \
	RESULTS=$$(RESULTS) \
	UNIKERNEL_INITRD=$$(UNIKERNEL_INITRD) \
		$$(APPSDIR)/$(1)/test.sh $$(TMPDIR)/wayfinder-build-$(1)/results

# Create the list of permutations file
plot: $$(APPSDIR)/$(1)/permutations-$$(NUM_COMPARTMENTS).csv
plot: plot-app-$(1)
$$(APPSDIR)/$(1)/permutations-$$(NUM_COMPARTMENTS).csv:
	$$(CAT) $$(TMPDIR)/wayfinder-build-$(1)/results/tasks.json | \
		$$(JQ) -r '(["TASKID"] + keys[0] as $$$$k | .[$$$$k] | keys_unsorted) as $$$$cols | to_entries | map([.key, .value[]]) as $$$$rows | $$$$cols,$$$$rows[] | @csv' > \
			$$@

# Create a plot entrypoint for the app
.PHONY: plot-app-$(1)
plot-app-$(1):
	$$(SNAKE) $$(APPSDIR)/$(1)/plot.py \
		$$(APPSDIR)/$(1)/permutations-$$(NUM_COMPARTMENTS).csv \
		$$(RESULTSDIR)/$(1).csv \
		$$(WORKDIR)/$$(notdir $$(WORKDIR))-$(1).$$(PLOT_FORMAT)

# Probide a target to clean up the experiment
.PHONY: properclean-wayfinder-app-$(1)
properclean: properclean-wayfinder-app-$(1)
properclean-wayfinder-app-$(1):
	$$(RM) -r $$(TMPDIR)/wayfinder-build-$(1)/

endef

$(foreach APP,$(APPS), \
	$(eval $(call prepare-wayfinder-app,$(APP))) \
)
 
.PHONY: install-wayfinder
install-wayfinder: WAYFINDER_VERSION=0.1.0
install-wayfinder: $(TMPDIR)/wayfinder.deb
	$(APT) install $(TMPDIR)/wayfinder.deb

$(TMPDIR)/wayfinder.deb: $(TMPDIR)
	$(WGET) -O $(TMPDIR)/wayfinder.deb https://github.com/lancs-net/wayfinder/releases/download/v$(WAYFINDER_VERSION)/wayfinder_$(WAYFINDER_VERSION)_linux_amd64.deb

$(TMPDIR):
	$(MKDIR) $@

$(RESULTSDIR):
	$(MKDIR) $@

.PHONY: run
run: run-wayfinder

.PHONY: run-wayfinder
run-wayfinder: WAYFINDER_CORES="1,2"
run-wayfinder:
	$(TASKSET) -c $(WAYFINDER_CORES) $(WAYFINDER)

.PHONY: plot
plot:

.PHONY: clean
clean:
	@-

.PHONY: properclean
properclean:
	$(RM) -f $(TMPDIR)
