#!/bin/bash
set -ex

KERNEL_VERSION=$(uname -r)
echo "open-iscsi for ${KERNEL_VERSION}"

STAMP=/lib/modules/${KERNEL_VERSION}/.open-iscsi-done

if [ -e $STAMP ]; then
    modprobe iscsi_tcp

    echo open-iscsi for ${KERNEL_VERSION} already installed. Delete $STAMP to reinstall
    exit 0
fi

OPENSSL_VERSION="OpenSSL_1_1_0j"
ISNS_VERSION="0.98"
ISCSI_VERSION="2.0.873"
SERVICE_VERSION="v2.0.873-1"

curl -sL https://github.com/openssl/openssl/archive/${OPENSSL_VERSION}.tar.gz > ${OPENSSL_VERSION}.tar.gz
tar zxf ${OPENSSL_VERSION}.tar.gz
rm -rf /dist/openssl
mv openssl-${OPENSSL_VERSION} /dist/openssl

curl -sL https://github.com/open-iscsi/open-isns/archive/v${ISNS_VERSION}.tar.gz > open-isns${ISNS_VERSION}.tar.gz
tar zxf open-isns${ISNS_VERSION}.tar.gz
rm -rf /dist/isns
mv open-isns-${ISNS_VERSION} /dist/isns

curl -sL https://github.com/open-iscsi/open-iscsi/archive/${ISCSI_VERSION}.tar.gz > open-iscsi${ISCSI_VERSION}.tar.gz
tar zxf open-iscsi${ISCSI_VERSION}.tar.gz
rm -rf /dist/iscsi
mv open-iscsi-${ISCSI_VERSION} /dist/iscsi

# install openssl
pushd /dist/openssl
./config
make -j$(nproc)
make DESTDIR=/dist/arch install
popd

# install isns
pushd /dist/isns
./configure
make -s -j$(nproc)
make DESTDIR=/dist/arch install
make DESTDIR=/dist/arch install_hdrs
make DESTDIR=/dist/arch install_lib
popd

# install iscsi
pushd /dist/iscsi
make -s -j$(nproc)
make DESTDIR=/dist/arch install
popd

# copy to console /opt dir
system-docker exec console mkdir -p /var/lib/rancher/extra-apps /var/lib/rancher/profile.d
pushd /dist/arch
system-docker cp . console:/var/lib/rancher/extra-apps/open-iscsi-${SERVICE_VERSION}

# copy profile file to console
cat << EOF > profile.sh
BASE=/var/lib/rancher/extra-apps/open-iscsi-${SERVICE_VERSION}

export PATH=\$PATH:\$BASE/sbin:\$BASE/usr/local/sbin
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$BASE/usr/local/lib:\$BASE/usr/local/lib64
EOF
chmod +x profile.sh
system-docker cp profile.sh console:/var/lib/rancher/profile.d/open-iscsi.sh
popd

modprobe iscsi_tcp

touch $STAMP
echo open-iscsi for ${KERNEL_VERSION} installed. Delete $STAMP to reinstall
