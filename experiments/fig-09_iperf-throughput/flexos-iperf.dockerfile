# You can easily build it with the following command:
# $ docker build --tag flexos-iperf .
#
# and run with:
# $ docker run --privileged --security-opt seccomp:unconfined -ti flexos-iperf bash
#
# (--security-opt seccomp:unconfined to limit docker overhead)

# Choose the base image for our final image
FROM debian:10

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "deb-src http://deb.debian.org/debian buster main contrib non-free" \
	>> /etc/apt/sources.list
RUN echo "deb-src http://security.debian.org/ buster/updates main contrib non-free" \
	>> /etc/apt/sources.list
RUN echo "deb-src http://deb.debian.org/debian/ buster-updates main contrib non-free" \
	>> /etc/apt/sources.list

RUN apt update
RUN apt build-dep -y coccinelle
RUN apt install -y flex bison wget unzip python3-pip git bc libffi-dev \
        build-essential libncurses-dev python3 expect-dev moreutils \
	flex unzip bison wget libxml2-utils tclsh python python-tempita python-six \
	python-future python-ply xorriso qemu-system-x86 qemu qemu-kvm vim \
	qemu-system qemu-utils curl gawk git procps socat uuid-runtime python3-pip \
	libiperf-dev bc net-tools bridge-utils libiscsi-dev librbd1 libnfs-dev \
	libgfapi0 iperf dnsmasq

##############
# Tools

WORKDIR /root

RUN wget https://raw.githubusercontent.com/unikraft/kraft/6217d48668cbdf0847c7864bc6368a6adb94f6a6/scripts/qemu-guest
RUN chmod a+x /root/qemu-guest

COPY docker-data/kraftcleanup /usr/local/bin/kraftcleanup
COPY docker-data/build-images.sh /root/
COPY docker-data/kraftrc.default /root/.kraftrc

RUN git clone https://github.com/project-flexos/kraft.git
RUN cd /root/kraft && git checkout a928f65036861051a17506a90dcaf81dbe1b6214 && pip3 install -e .

RUN git clone https://github.com/coccinelle/coccinelle
RUN cd coccinelle && git checkout ae337fce1512ff15aabc3ad5b6d2e537f97ab62a && \
			./autogen && ./configure && make && make install

# fix a bug in Coccinelle
RUN mkdir /usr/local/bin/lib
RUN ln -s /usr/local/lib/coccinelle /usr/local/bin/lib/coccinelle

##############
# FlexOS EPT QEMU

RUN git clone https://github.com/qemu/qemu.git

WORKDIR /root/qemu

RUN git checkout 9ad4c7c9b63f89c308fd988d509bed1389953c8b
COPY docker-data/0001-Myshmem.patch /root/0001-Myshmem.patch
RUN git apply /root/0001-Myshmem.patch
RUN apt build-dep -y qemu-system-x86
RUN apt install ninja-build
RUN ./configure --target-list=x86_64-softmmu
RUN sed -i -e 's/-lstdc++ -Wl,--end-group/-lrt -lstdc++ -Wl,--end-group/g' build/build.ninja
RUN make -j8
RUN cp build/qemu-system-x86_64 /root/qemu-system-ept
RUN cp -r build/pc-bios /root/pc-bios
RUN rm /root/0001-Myshmem.patch

WORKDIR /root

##############
# FlexOS (KVM)

WORKDIR /root/.unikraft/apps

# build flexos with 2 mpk compartments (iperf/rest) and private stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 4281a7e6070baeb03f5b52a1e8793c871a5df493
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
COPY docker-data/iperf-flexos-mpk2.config /root/.unikraft/apps/iperf/.config
RUN cd iperf && make prepare && kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/kvmflexos-start.sh /root/.unikraft/apps/iperf/kvm-start.sh
RUN cd iperf && /root/build-images.sh && rm -rf build/
RUN mv iperf iperf-mpk2-isolstack

# build flexos with 2 mpk compartments (iperf/rest) and shared stacks
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 4281a7e6070baeb03f5b52a1e8793c871a5df493
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

ARG UK_KRAFT_GITHUB_TOKEN=
ENV UK_KRAFT_GITHUB_TOKEN=${UK_KRAFT_GITHUB_TOKEN}

# build flexos with 2 ept compartments (iperf/rest)
RUN kraftcleanup
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
RUN cd /root/.unikraft/unikraft && git checkout 4281a7e6070baeb03f5b52a1e8793c871a5df493
COPY docker-data/iperf-ept2.patch /root/iperf-ept2.patch
RUN cd /root/.unikraft/unikraft && git apply /root/iperf-ept2.patch
COPY docker-data/iperf-flexos-ept2.config iperf/.config
COPY docker-data/kraft.yaml.ept2 iperf/kraft.yaml
RUN cd iperf && /root/build-images.sh && rm -rf build/
COPY docker-data/kvmflexosept2-start.sh iperf/kvm-start.sh
RUN mv iperf iperf-ept2

# build flexos with no compartments
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 4281a7e6070baeb03f5b52a1e8793c871a5df493
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" /root/.unikraft/libs/lwip/include/lwipopts.h
RUN mv /root/.unikraft/apps/iperf /root/.unikraft/apps/iperf-fcalls
COPY docker-data/iperf-flexos-fcalls.config /root/.unikraft/apps/iperf-fcalls/.config
COPY docker-data/img.cpio /root/.unikraft/apps/iperf-fcalls/
COPY docker-data/kraft.yaml.fcalls /root/.unikraft/apps/iperf-fcalls/kraft.yaml
RUN cd iperf-fcalls && make prepare && kraft -v build --no-progress --fast --compartmentalize
RUN cd iperf-fcalls && /root/build-images.sh && rm -rf build/
COPY docker-data/kvmflexos-start.sh /root/.unikraft/apps/iperf-fcalls/kvm-start.sh

RUN mv /root/.unikraft /root/flexos

##############
# Unikraft 0.5 (KVM and linuxu)
# Performance is similar to Unikraft 0.4, so omit it.

RUN mkdir /root/unikraft-mainline

WORKDIR /root/unikraft-mainline

RUN git clone https://github.com/unikraft/unikraft.git
RUN cd /root/unikraft-mainline/unikraft && \
       git checkout fd5779120a5938d5c814583cb0f59046b1756cd3

RUN mkdir libs apps

WORKDIR /root/unikraft-mainline/libs

RUN git clone https://github.com/unikraft/lib-newlib.git
RUN cd lib-newlib && git checkout ddc25cf1f361e33d1003ce1842212e8ff37b1e08

RUN git clone https://github.com/unikraft/lib-pthread-embedded.git
RUN cd lib-pthread-embedded && git checkout 2dd71294ab5fac328e62932992550405c866c7e8

RUN cp -r /root/flexos/libs/iperf lib-iperf
# use unikraft baseline branch
RUN cd lib-iperf && git clean -xdf && git checkout . && git checkout 120324e7986f8fb7a90debd7637708c8485de519

RUN git clone https://github.com/unikraft/lib-tlsf.git
RUN cd lib-tlsf && git checkout ae4f7402a2c5ee6040dab799b397537177306cc9

RUN git clone https://github.com/unikraft/lib-lwip.git
RUN cd lib-lwip && git checkout 3c85bd46a3f764039d8f6e3128c8f5d7096dbd13
RUN sed -i "s/TCP_WND 32766/TCP_WND 65335/g" lib-lwip/include/lwipopts.h

WORKDIR /root/unikraft-mainline/apps

RUN cp -r /root/flexos/apps/iperf-fcalls/ app-iperf
# use unikraft baseline branch
RUN cd app-iperf && git clean -xdf && git checkout . && git checkout 7cda87c1b39398b7338a01bb59bdefdcc03efd73
COPY docker-data/iperf-unikraft.config app-iperf/.config
RUN cd app-iperf && /root/build-images.sh && rm -rf build/
RUN cp /root/flexos/apps/iperf-fcalls/kvm-start.sh app-iperf/kvm-start.sh

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
