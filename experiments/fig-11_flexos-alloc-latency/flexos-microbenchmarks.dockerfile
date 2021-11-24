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

ARG UK_KRAFT_GITHUB_TOKEN=
ENV UK_KRAFT_GITHUB_TOKEN=${UK_KRAFT_GITHUB_TOKEN}

##############
# FlexOS (KVM)

WORKDIR /root/.unikraft/apps

# build flexos with 2 mpk compartments (microbenchmarks/rest) and private stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
COPY docker-data/configs/microbenchmarks-flexos-mpk2.config /root/.unikraft/apps/microbenchmarks/.config
RUN cd microbenchmarks && make prepare && kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/start-scripts/kvmflexos-start.sh /root/.unikraft/apps/microbenchmarks/kvm-start.sh
RUN cd microbenchmarks && /root/build-images.sh && rm -rf build/
RUN mv microbenchmarks microbenchmarks-mpk2-isolstack

# build flexos with 2 mpk compartments (microbenchmarks/rest) and shared stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
RUN rm -rf /root/.unikraft/apps/microbenchmarks && cp -r microbenchmarks-mpk2-isolstack microbenchmarks-mpk2-noisolstack
RUN sed -i "s/CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS=y/# CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS is not set/g" \
	microbenchmarks-mpk2-noisolstack/.config
RUN sed -i "s/CONFIG_LIBFLEXOS_ENABLE_DSS=y/# CONFIG_LIBFLEXOS_ENABLE_DSS is not set/g" \
	microbenchmarks-mpk2-noisolstack/.config
RUN sed -i "s/# CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS is not set/CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS=y/g" \
	microbenchmarks-mpk2-noisolstack/.config
RUN cd microbenchmarks-mpk2-noisolstack && rm -rf images build
RUN cd microbenchmarks-mpk2-noisolstack && make prepare && kraft -v build --no-progress --fast --compartmentalize
RUN cd microbenchmarks-mpk2-noisolstack && /root/build-images.sh && rm -rf build/

# build flexos with 2 ept compartments (microbenchmarks/rest)
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
COPY docker-data/microbenchmarks-ept2.patch /root/microbenchmarks-ept2.patch
RUN cd /root/.unikraft/unikraft && git apply /root/microbenchmarks-ept2.patch
COPY docker-data/configs/microbenchmarks-flexos-ept2.config microbenchmarks/.config
COPY docker-data/configs/kraft.yaml.ept2 microbenchmarks/kraft.yaml
RUN cd microbenchmarks && /root/build-images.sh && rm -rf build/
COPY docker-data/start-scripts/kvmflexosept2-start.sh microbenchmarks/kvm-start.sh
RUN mv microbenchmarks microbenchmarks-ept2

RUN mv /root/.unikraft /root/flexos

##############
# Linux (function calls, syscalls with and without KPTI)

# TODO

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
