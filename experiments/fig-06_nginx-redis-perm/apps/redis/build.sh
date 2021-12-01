#!/bin/bash

# Just ensure the environment is OK for kraft
export UK_WORKDIR=/usr/src/unikraft
export UK_CACHEDIR=/usr/src/unikraft/.kraftcache
export KRAFTRC=/usr/src/unikraft/.kraftrc
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
for env in $(cat /etc/environment); do \
  export $(echo $env | sed -e 's/"//g'); \
done

NUM_COMPARTMENTS=${NUM_COMPARTMENTS:-1}
TEMPLDIR=${TEMPLDIR:-/kraft-yaml-template}
TEMPDIR=$(mktemp -d)

cp -rfv $TEMPLDIR/* $TEMPDIR

KRAFT_BUILD_EXTRA=()
KRAFT_BUILD_EXTRA+=(V=1)
USE_UBSAN=n
USE_KASAN=n
USE_SP=n

SFI_FLAGS='"-fsanitize=undefined -fsanitize=kernel-address -fstack-protector-all -mstack-protector-guard=global"'

for ENV in $(env); do
  # Iterate over unique libs
  if [[ "${ENV:0:3}" != "LIB" ]]; then continue; fi
  LIB=${ENV%=*}
  if [ "${LIB: -12}" != "_COMPARTMENT" ]; then continue; fi

  LIB=${LIB%_COMPARTMENT*}
  COMPARTMENT="${LIB}_COMPARTMENT"
  cat << EOF >> ${TEMPDIR}/data.yaml
  ${LIB}: ${!COMPARTMENT}
EOF

  USE_SFI="${LIB}_SFI"
  if [[ "${!USE_SFI}" == "y" ]]; then
    USE_UBSAN=y
    USE_KASAN=y
    USE_UKSP=y

    if [[ "${LIB}" == "LIBNEWLIB" ]]; then
      KRAFT_BUILD_EXTRA+=(LIBNEWLIB_CFLAGS_EXTRA="${SFI_FLAGS}")
    elif [[ "${LIB}" == "LIBUKSCHED" ]]; then
      KRAFT_BUILD_EXTRA+=(LIBUKSCHED_CFLAGS="${SFI_FLAGS}")
      KRAFT_BUILD_EXTRA+=(LIBUKSCHEDCOOP_CFLAGS="${SFI_FLAGS}")
    # elif [[ "${LIB}" == "LIBREDIS" ]]; then
    #   KRAFT_BUILD_EXTRA+=(LIBREDIS_LUA_CFLAGS_EXTRA="${SFI_FLAGS}")
    #   KRAFT_BUILD_EXTRA+=(LIBREDIS_HIREDIS_CFLAGS_EXTRA="${SFI_FLAGS}")
    #   KRAFT_BUILD_EXTRA+=(LIBREDIS_COMMON_CFLAGS_EXTRA="${SFI_FLAGS}")
    #   KRAFT_BUILD_EXTRA+=(LIBREDIS_SERVER_CFLAGS_EXTRA="${SFI_FLAGS}")
    #   KRAFT_BUILD_EXTRA+=(LIBREDIS_CLIENT_CFLAGS_EXTRA="${SFI_FLAGS}")
    else
      KRAFT_BUILD_EXTRA+=(${LIB}_CFLAGS_EXTRA="${SFI_FLAGS}")
    fi
  fi
done

echo "compartments:" >> ${TEMPDIR}/data.yaml

for ((I=1; I<=$NUM_COMPARTMENTS; I++)); do
  DEFAULT="false"
  if [[ "${I}" == "1" ]]; then
    DEFAULT="true"
  fi

  COMPARTMENT_DRIVER="COMPARTMENT${I}_DRIVER"
  COMPARTMENT_ISOLSTACK="COMPARTMENT${I}_ISOLSTACK"

  cat << EOF >> ${TEMPDIR}/data.yaml
  - name: comp${I}
    mechanism:
      driver: ${!COMPARTMENT_DRIVER}
      noisolstack: ${!COMPARTMENT_ISOLSTACK}
    default: ${DEFAULT}
EOF
done

ytt \
  --data-value num_compartments=$NUM_COMPARTMENTS \
  --file ${TEMPDIR} > /usr/src/unikraft/apps/redis/kraft.yaml

cd /usr/src/unikraft/apps/redis/

KRAFT_CONFIGURE_EXTRA=()
if [[ "${USE_UBSAN}" == "y" ]]; then
  KRAFT_CONFIGURE_EXTRA+=(--yes LIBUBSAN)
fi
if [[ "${USE_KASAN}" == "y" ]]; then
  KRAFT_CONFIGURE_EXTRA+=(--yes LIBKASAN)
fi
if [[ "${USE_UKSP}" == "y" ]]; then
  KRAFT_CONFIGURE_EXTRA+=(--yes LIBUKSP)
fi

set -xe

kraft -v configure -F "${KRAFT_CONFIGURE_EXTRA[@]}" |& tee build.log

cp .config config
echo "# Extra from build.sh" >> config
echo "# configure params:" >> config
echo "# ${KRAFT_CONFIGURE_EXTRA[@]}" >> config
echo "# build params:" >> config
echo "# ${KRAFT_BUILD_EXTRA[@]}" >> config

kraft -v build \
  --fast \
  --no-progress \
  --compartmentalize \
  "${KRAFT_BUILD_EXTRA[@]}" |& tee -a build.log
