# You can easily build it with the following command:
# $ docker build --tag flexos-microbenchmarks -f flexos-microbenchmarks.dockerfile .
#
# If the build fails because you are rate-limited by GitHub, generate an app
# token () and run instead:
# $ docker build --build-arg UK_KRAFT_GITHUB_TOKEN="<YOUR TOKEN>" --tag flexos-microbenchmarks
#
# and run with:
# $ docker run --privileged --security-opt seccomp:unconfined -ti flexos-microbenchmarks bash
#
# (--security-opt seccomp:unconfined to limit docker overhead)

FROM ghcr.io/project-flexos/flexos-ae-base:latest

ARG GITHUB_TOKEN=
ENV UK_KRAFT_GITHUB_TOKEN=${GITHUB_TOKEN}

##############
# FlexOS (KVM)

WORKDIR /root/.unikraft/apps

# build flexos with 2 mpk compartments (microbenchmarks/rest) and private stacks with DSS
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
COPY docker-data/configs/microbenchmarks-flexos-mpk2.config flexos-microbenchmarks/.config
COPY docker-data/configs/kraft.yaml.mpk2 flexos-microbenchmarks/kraft.yaml
COPY docker-data/start-scripts/kvmflexos-start.sh flexos-microbenchmarks/kvm-start.sh
RUN cd flexos-microbenchmarks && make prepare && kraft -v build --no-progress --fast --compartmentalize
RUN mv flexos-microbenchmarks flexos-microbenchmarks-mpk2-isolstack

# build flexos with 2 mpk compartments (microbenchmarks/rest) and private stacks without DSS
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
# generated by kraftcleanup, we don't need it as noisolstack
# is only 3 config options away from the previous build
RUN rm -rf /root/.unikraft/apps/flexos-microbenchmarks
RUN cp -r flexos-microbenchmarks-mpk2-isolstack flexos-microbenchmarks-mpk2-isolstack-heap
WORKDIR /root/.unikraft/apps/flexos-microbenchmarks-mpk2-isolstack-heap
RUN git checkout main.c
RUN sed -i "s/CONFIG_LIBFLEXOS_ENABLE_DSS=y/# CONFIG_LIBFLEXOS_ENABLE_DSS is not set/g" \
	.config
RUN rm -rf build && make prepare && kraft -v build --no-progress --fast --compartmentalize
WORKDIR /root/.unikraft/apps

# build flexos with 2 mpk compartments (microbenchmarks/rest) and shared stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
# generated by kraftcleanup, we don't need it as noisolstack
# is only 3 config options away from the previous build
RUN rm -rf /root/.unikraft/apps/flexos-microbenchmarks
RUN cp -r flexos-microbenchmarks-mpk2-isolstack flexos-microbenchmarks-mpk2-noisolstack
WORKDIR /root/.unikraft/apps/flexos-microbenchmarks-mpk2-noisolstack
RUN git checkout main.c
RUN sed -i "s/CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS=y/# CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS is not set/g" \
	.config
RUN sed -i "s/CONFIG_LIBFLEXOS_ENABLE_DSS=y/# CONFIG_LIBFLEXOS_ENABLE_DSS is not set/g" \
	.config
RUN sed -i "s/# CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS is not set/CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS=y/g" \
	.config
RUN rm -rf build && make prepare && kraft -v build --no-progress --fast --compartmentalize
WORKDIR /root/.unikraft/apps

# build flexos with 2 ept compartments (microbenchmarks/rest)
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && \
    git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a && \
    git apply /root/ept2-tmpfix.patch
COPY docker-data/configs/microbenchmarks-flexos-ept2.config flexos-microbenchmarks/.config
COPY docker-data/configs/kraft.yaml.ept2 flexos-microbenchmarks/kraft.yaml
COPY docker-data/start-scripts/kvmflexosept2-start.sh flexos-microbenchmarks/kvm-start.sh
# no --no-progress here
RUN cd flexos-microbenchmarks && make prepare && kraft -v build --fast --compartmentalize
RUN mv flexos-microbenchmarks flexos-microbenchmarks-ept2

RUN mv /root/.unikraft /root/flexos

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
