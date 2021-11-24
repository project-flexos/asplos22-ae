# You can easily build it with the following command:
# $ docker build --tag flexos-microbenchmarks -f flexos-microbenchmarks.dockerfile .
#
# If the build fails because you are rate-limited by GitHub, generate an app
# token () and run instead:
# $ docker build --build-arg UK_KRAFT_GITHUB_TOKEN="<YOUR TOKEN>" --tag flexos-iperf
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

# build flexos with 2 mpk compartments (iperf/rest) and private stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
COPY docker-data/configs/iperf-flexos-mpk2.config /root/.unikraft/apps/iperf/.config
RUN cd iperf && make prepare && kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/start-scripts/kvmflexos-start.sh /root/.unikraft/apps/iperf/kvm-start.sh
RUN cd iperf && /root/build-images.sh && rm -rf build/
RUN mv iperf iperf-mpk2-isolstack

# build flexos with 2 mpk compartments (iperf/rest) and shared stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
RUN rm -rf /root/.unikraft/apps/iperf && cp -r iperf-mpk2-isolstack iperf-mpk2-noisolstack
RUN sed -i "s/CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS=y/# CONFIG_LIBFLEXOS_GATE_INTELPKU_PRIVATE_STACKS is not set/g" \
	iperf-mpk2-noisolstack/.config
RUN sed -i "s/CONFIG_LIBFLEXOS_ENABLE_DSS=y/# CONFIG_LIBFLEXOS_ENABLE_DSS is not set/g" \
	iperf-mpk2-noisolstack/.config
RUN sed -i "s/# CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS is not set/CONFIG_LIBFLEXOS_GATE_INTELPKU_SHARED_STACKS=y/g" \
	iperf-mpk2-noisolstack/.config
RUN cd iperf-mpk2-noisolstack && rm -rf images build
RUN cd iperf-mpk2-noisolstack && make prepare && kraft -v build --no-progress --fast --compartmentalize
RUN cd iperf-mpk2-noisolstack && /root/build-images.sh && rm -rf build/

# build flexos with 2 ept compartments (iperf/rest)
RUN kraftcleanup
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
COPY docker-data/iperf-ept2.patch /root/iperf-ept2.patch
RUN cd /root/.unikraft/unikraft && git apply /root/iperf-ept2.patch
COPY docker-data/configs/iperf-flexos-ept2.config iperf/.config
COPY docker-data/configs/kraft.yaml.ept2 iperf/kraft.yaml
RUN cd iperf && /root/build-images.sh && rm -rf build/
COPY docker-data/start-scripts/kvmflexosept2-start.sh iperf/kvm-start.sh
RUN mv iperf iperf-ept2

RUN mv /root/.unikraft /root/flexos

##############
# Linux (function calls, syscalls with and without KPTI)

# TODO

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
