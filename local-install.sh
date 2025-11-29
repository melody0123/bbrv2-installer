#!/bin/bash
# Build a Linux kernel as a Debian Package (.deb)
# This script is only tested on Ubuntu 22.04 with kernel 5.15.0

set -e

usage() {
    echo "${0} [ -h | -v ]"
}

VERBOSE=""

while getopts "hv" opt; do
    case "${opt}" in
        h)
            usage
            exit 0
            ;;
        v)
            VERBOSE="set -x"
            ;;
    esac
done

${VERBOSE}

# --- Install Deps ---
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev -y

# Note: must use pahole <= 1.23 to avoid BTF error during kernel compiling
curl -O https://launchpadlibrarian.net/596956770/dwarves_1.22-8_all.deb
curl -O https://launchpadlibrarian.net/596956773/pahole_1.22-8_amd64.deb
sudo dpkg -i pahole_1.22-8_amd64.deb
sudo dpkg -i dwarves_1.22-8_all.deb

# --- Git Clone ---
git clone -b v2alpha https://github.com/google/bbr.git
cd bbr

# --- Configuration ---
BRANCH=`git rev-parse --abbrev-ref HEAD | sed s/-/+/g`
SHA1=`git rev-parse --short HEAD`
LOCALVERSION=+${BRANCH}+${SHA1}
PKG_DIR=${PWD}/${LOCALVERSION}/debs

# Note: bindeb-pkg creates packages in the PARENT directory (../). 
# We don't need INSTALL_DIR anymore because the package build creates its own structure.

echo "cleaning..."
mkdir -p ${PKG_DIR}

echo "copying config-$(uname -r) to .config ..."
cp /boot/config-$(uname -r) .config

echo "disabling signing keys ..."
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS

echo "enabling BBRv2"
scripts/config --enable CONFIG_TCP_CONG_BBR2
scripts/config --module CONFIG_TCP_CONG_BBR2

echo "running make olddefconfig ..."
make olddefconfig | tee -a /tmp/make.olddefconfig

# --- The Magic Step ---
# 'bindeb-pkg' builds the kernel image, modules, and headers, 
# then wraps them into .deb files.
# We skip the separate 'make' and 'make modules' steps because this target does it all.
echo "Compiling and building .deb packages (this will take time)..."

make -j$(nproc) bindeb-pkg LOCALVERSION=${LOCALVERSION} | tee -a /tmp/make.bindeb-pkg

# --- Cleanup & Organize ---
# The build system outputs .deb files in the PARENT directory (../).
# We move them into your specific PKG_DIR for cleanliness.
echo "Moving .deb files to ${PKG_DIR}..."
mv ../linux-image*${LOCALVERSION}*.deb ${PKG_DIR}/
mv ../linux-headers*${LOCALVERSION}*.deb ${PKG_DIR}/
mv ../linux-libc-dev*${LOCALVERSION}*.deb ${PKG_DIR}/ 2>/dev/null || true

# --- Installing ---
sudo dpkg -i ${PKG_DIR}/*.deb
