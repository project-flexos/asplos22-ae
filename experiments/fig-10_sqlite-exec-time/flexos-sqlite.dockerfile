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
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
COPY docker-data/configs/sqlite-flexos-mpk3.config /root/.unikraft/apps/sqlite/.config
COPY docker-data/sqlite.cpio /root/.unikraft/apps/sqlite/
COPY docker-data/configs/kraft.yaml.mpk3 /root/.unikraft/apps/sqlite/kraft.yaml
RUN cd /root/.unikraft/apps/sqlite && make prepare && \
	kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/start-scripts/kvmflexosmpk3-start.sh /root/.unikraft/apps/sqlite/kvm-start.sh
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-mpk3

# build flexos with 2 compartments (EPT, vfscore/rest)
RUN kraftcleanup
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-ept2
COPY docker-data/configs/sqlite-flexos-ept2.config /root/.unikraft/apps/sqlite-ept2/.config
COPY docker-data/configs/kraft.yaml.ept2 /root/.unikraft/apps/sqlite-ept2/kraft.yaml
COPY docker-data/patches/flexos-ept2.diff /root/.unikraft/apps/sqlite-ept2/
COPY docker-data/patches/flexos-ept2.diff.2 /root/.unikraft/apps/sqlite-ept2/
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a && \
	git apply /root/.unikraft/apps/sqlite-ept2/flexos-ept2.diff.2
# no --no-progress here
RUN cd /root/.unikraft/apps/sqlite-ept2 && git apply flexos-ept2.diff && \
	make prepare && kraft -v build --fast --compartmentalize
COPY docker-data/start-scripts/kvmflexosept2-start.sh /root/.unikraft/apps/sqlite-ept2/kvm-start.sh

# build flexos with no compartments
RUN kraftcleanup
RUN cd /root/.unikraft/unikraft && git checkout 66f546dc6a2d8e13b47846ee29450f75b3ad388a
RUN mv /root/.unikraft/apps/sqlite /root/.unikraft/apps/sqlite-fcalls
COPY docker-data/configs/sqlite-flexos-fcalls.config /root/.unikraft/apps/sqlite-fcalls/.config
COPY docker-data/sqlite.cpio /root/.unikraft/apps/sqlite-fcalls/
COPY docker-data/configs/kraft.yaml.fcalls /root/.unikraft/apps/sqlite-fcalls/kraft.yaml
RUN cd /root/.unikraft/apps/sqlite-fcalls && make prepare && \
	kraft -v build --no-progress --fast --compartmentalize
COPY docker-data/start-scripts/kvmflexosfcalls-start.sh /root/.unikraft/apps/sqlite-fcalls/kvm-start.sh

RUN mv /root/.unikraft /root/flexos

##############
# Unikraft 0.5 (KVM and linuxu)
# Performance is similar to Unikraft 0.4, so omit it.

WORKDIR /root/unikraft-mainline/unikraft/

# apply cpio patches

COPY docker-data/patches/cpio-patches/ cpio-patches/
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

COPY docker-data/configs/sqlite-kvm.config app-sqlite-kvm/.config
COPY docker-data/start-scripts/kvm-start.sh app-sqlite-kvm/
RUN cd app-sqlite-kvm && make prepare && make -j

COPY docker-data/configs/sqlite-linuxu.config app-sqlite-linuxu/.config
COPY docker-data/start-scripts/linuxu-start.sh app-sqlite-linuxu/
RUN cd app-sqlite-linuxu && make prepare && make -j

##############
# CubicleOS (linuxu) w/ and w/o MPK

RUN mkdir -p /root/cubicleos
WORKDIR /root/cubicleos

RUN git clone https://github.com/lsds/CubicleOS.git && cd CubicleOS && \
	git checkout ASPLOS_AE

COPY docker-data/patches/cubicleos.diff /root/cubicleos/
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
COPY docker-data/start-scripts/process-start.sh .
RUN gcc main.c -lsqlite3 -O2 -o ./sqlite-benchmark


##############
# Genode (KVM) 3 compartments

ADD https://www.doc.ic.ac.uk/~vsartako/asplos/genode.tar.gz /root
ADD https://www.doc.ic.ac.uk/~vsartako/asplos/tch.tar.xz  /root
RUN cd / && tar -xf /root/tch.tar.xz
RUN cd / && tar -xf /root/genode.tar.gz
WORKDIR /genode
RUN mv /root/genode.tar.gz .
RUN mv /root/tch.tar.xz .
COPY docker-data/main.c repos/sqlite/src/sqlite/main.c
RUN sed -i '/<arg value="--size" \/>/d' repos/sqlite/run/sqlite.run
RUN sed -i '/<arg value="100" \/>/d' repos/sqlite/run/sqlite.run
RUN sed -i '/<arg value="--stats" \/>/d' repos/sqlite/run/sqlite.run
# this triggers warnings that skew results
RUN sed -i 's/osFchown(fd,uid,gid)/0/g' /genode/repos/sqlite/src/sqlite/sqlite3.c
RUN ./tool/create_builddir x86_64
COPY docker-data/configs/genode.conf build/x86_64/etc/build.conf

##############
# Finish

WORKDIR /root

COPY docker-data/run.sh .
RUN chmod u+x run.sh
