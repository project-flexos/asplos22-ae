#
# Directories
#
WORKDIR ?= $(CURDIR)

#
# General configuration
#
REG     ?= ghcr.io
ORG     ?= ukflexos
IMAGES  ?= flexos-base \
           nginx \
           redis

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
# Targets
#
.PHONY: docker
docker: $(DIMAGES)

.PHONY: $(DIMAGES)
$(DIMAGES): TAG ?= latest
$(DIMAGES):
	$(Q)$(DOCKER) build \
		--tag $(REG)/$(ORG)/$(@:docker-%=%):$(TAG) \
		--file $(WORKDIR)/support/dockerfiles/Dockerfile.$(@:docker-%=%) \
		$(WORKDIR)/support/dockerfiles
