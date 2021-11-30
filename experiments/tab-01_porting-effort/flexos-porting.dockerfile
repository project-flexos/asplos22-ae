# You can easily build it with the following command:
# $ docker build --tag flexos-iperf -f flexos-iperf.dockerfile .
#
# If the build fails because you are rate-limited by GitHub, generate an app
# token () and run instead:
# $ docker build --build-arg UK_KRAFT_GITHUB_TOKEN="<YOUR TOKEN>" --tag flexos-iperf
#
# and run with:
# $ docker run --privileged --security-opt seccomp:unconfined -ti flexos-iperf bash
#
# (--security-opt seccomp:unconfined to limit docker overhead)

FROM ghcr.io/project-flexos/flexos-ae-base:latest

ARG UK_KRAFT_GITHUB_TOKEN=
ENV UK_KRAFT_GITHUB_TOKEN=${UK_KRAFT_GITHUB_TOKEN}

WORKDIR /root/.unikraft/apps
RUN kraftcleanup

RUN mv /root/.unikraft /root/flexos

##############
# Finish

WORKDIR /root
