# You can easily build it with the following command:
# $ docker build --tag flexos-sqlite -f flexos-sqlite.dockerfile .
#
# If the build fails because you are rate-limited by GitHub, generate an app
# token () and run instead:
# $ docker build --build-arg UK_KRAFT_GITHUB_TOKEN="<YOUR TOKEN>" --tag flexos-sqlite
#
# and run with:
# $ docker run --privileged --security-opt seccomp:unconfined -ti flexos-sqlite bash
#
# (--security-opt seccomp:unconfined to limit docker overhead)

FROM ghcr.io/project-flexos/flexos-ae-base:latest

ARG UK_KRAFT_GITHUB_TOKEN=
ENV UK_KRAFT_GITHUB_TOKEN=${UK_KRAFT_GITHUB_TOKEN}

##############
# FlexOS (KVM)

WORKDIR /root

# build flexos with 3 compartments (vfscore+ramfs/uktime/rest)
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 4d5daa85cfb43dccc152d5dd39928ea0b6085f49
COPY docker-data/sqlite-flexos-mpk3.config /root/.unikraft/apps/sqlite/.config
COPY docker-data/sqlite.cpio /root/.unikraft/apps/sqlite/
COPY docker-data/kraft.yaml.mpk3 /root/.unikraft/apps/sqlite/kraft.yaml
RUN cd /root/.unikraft/apps/sqlite && make prepare && \
	kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/kvmflexosmpk3-start.sh /root/.unikraft/apps/sqlite/kvm-start.sh
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-mpk3

# build flexos with 2 compartments (EPT, vfscore/rest)
RUN kraftcleanup
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-ept2
COPY docker-data/sqlite-flexos-ept2.config /root/.unikraft/apps/sqlite-ept2/.config
COPY docker-data/kraft.yaml.ept2 /root/.unikraft/apps/sqlite-ept2/kraft.yaml
COPY docker-data/flexos-ept2.diff /root/.unikraft/apps/sqlite-ept2/
COPY docker-data/flexos-ept2.diff.2 /root/.unikraft/apps/sqlite-ept2/
RUN cd /root/.unikraft/unikraft && git checkout 4d5daa85cfb43dccc152d5dd39928ea0b6085f49 && \
	git apply /root/.unikraft/apps/sqlite-ept2/flexos-ept2.diff.2
# no --no-progress here
RUN cd /root/.unikraft/apps/sqlite-ept2 && git apply flexos-ept2.diff && \
	make prepare && kraft -v build --fast --compartmentalize
COPY docker-data/kvmflexosept2-start.sh /root/.unikraft/apps/sqlite-ept2/kvm-start.sh

# build flexos with no compartments
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 4d5daa85cfb43dccc152d5dd39928ea0b6085f49
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-fcalls
COPY docker-data/sqlite-flexos-fcalls.config /root/.unikraft/apps/sqlite-fcalls/.config
COPY docker-data/sqlite.cpio /root/.unikraft/apps/sqlite-fcalls/
COPY docker-data/kraft.yaml.fcalls /root/.unikraft/apps/sqlite-fcalls/kraft.yaml
RUN cd /root/.unikraft/apps/sqlite-fcalls && make prepare && \
	kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/kvmflexosfcalls-start.sh /root/.unikraft/apps/sqlite-fcalls/kvm-start.sh

RUN mv /root/.unikraft /root/flexos

##############
# Unikraft 0.5 (KVM and linuxu)
# Performance is similar to Unikraft 0.4, so omit it.

WORKDIR /root/unikraft-mainline/unikraft/

# apply cpio patches

COPY docker-data/cpio-patches/ cpio-patches/
RUN patch -p1 < cpio-patches/01.patch
RUN patch -p1 < cpio-patches/02.patch
RUN patch -p1 < cpio-patches/03.patch
RUN patch -p1 < cpio-patches/04.patch
RUN patch -p1 < cpio-patches/05.patch

WORKDIR /root/unikraft-mainline/libs

RUN git clone https://github.com/unikraft/lib-newlib.git
RUN cd lib-newlib && git checkout ddc25cf1f361e33d1003ce1842212e8ff37b1e08

RUN git clone https://github.com/unikraft/lib-pthread-embedded.git
RUN cd lib-pthread-embedded && git checkout 2dd71294ab5fac328e62932992550405c866c7e8

RUN git clone https://github.com/unikraft/lib-sqlite.git
RUN cd lib-sqlite && git checkout 21ec31d578295982619a164de96b653e93e7cf9c

RUN git clone https://github.com/unikraft/lib-tlsf.git
RUN cd lib-tlsf && git checkout ae4f7402a2c5ee6040dab799b397537177306cc9

WORKDIR /root/unikraft-mainline/apps

RUN mkdir -p app-sqlite-kvm

RUN cd app-sqlite-kvm && \
	echo "\$(eval \$(call addlib,appsqlite))" > Makefile.uk
RUN cd app-sqlite-kvm && \
	echo "APPSQLITE_SRCS-y += \$(APPSQLITE_BASE)/main.c" >> Makefile.uk
RUN cd app-sqlite-kvm && \
	echo "APPSQLITE_CINCLUDES-y += -I\$(APPSQLITE_BASE)/include" >> Makefile.uk

COPY docker-data/Makefile app-sqlite-kvm/
COPY docker-data/main.c app-sqlite-kvm/
COPY docker-data/include app-sqlite-kvm/

RUN cp -r app-sqlite-kvm app-sqlite-linuxu
RUN sed -i -e "s/#if 1/#if 0/g" app-sqlite-kvm/main.c

COPY docker-data/sqlite-kvm.config app-sqlite-kvm/.config
COPY docker-data/kvm-start.sh app-sqlite-kvm/
RUN cd app-sqlite-kvm && make prepare && make -j

COPY docker-data/sqlite-linuxu.config app-sqlite-linuxu/.config
COPY docker-data/linuxu-start.sh app-sqlite-linuxu/
RUN cd app-sqlite-linuxu && make prepare && make -j

##############
# CubicleOS (linuxu) w/ and w/o MPK

RUN mkdir -p /root/cubicleos
WORKDIR /root/cubicleos

RUN git clone https://github.com/lsds/CubicleOS.git && cd CubicleOS && \
	git checkout ASPLOS_AE

COPY docker-data/cubicleos.diff /root/cubicleos/
RUN cd CubicleOS/ && patch -p1 < /root/cubicleos/cubicleos.diff
RUN cd CubicleOS/CubicleOS/app-sqlite/ && make
RUN cd CubicleOS/CubicleOS/kernel/ && make sqlite
RUN mv CubicleOS/CubicleOS/kernel/run.sh CubicleOS/CubicleOS/kernel/linuxu-start.sh
RUN mv CubicleOS/CubicleOS/app-sqlite/run.sh CubicleOS/CubicleOS/app-sqlite/linuxu-start.sh

##############
# Linux (process)

RUN mkdir -p /root/linux-userland
WORKDIR /root/linux-userland
COPY docker-data/main.c .
COPY docker-data/process-start.sh .
RUN gcc main.c -lsqlite3 -O2 -o ./sqlite-benchmark


##############
# Genode (KVM) 3 compartments

ADD https://www.doc.ic.ac.uk/~vsartako/asplos/genode.tar.gz /
ADD https://www.doc.ic.ac.uk/~vsartako/asplos/tch.tar.xz  /
RUN tar -xf /genode.tar.gz
RUN tar -xf /tch.tar.xz
COPY docker-data/main.c /

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
