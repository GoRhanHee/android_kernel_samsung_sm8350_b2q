#!/bin/bash

# submodule
git submodule init && git submodule update --remote

# Compiling Setting
export KSU=$1
export ANDROID_BUILD_TOP=$(pwd)

# Define toolchain variables
CLANG_DIR=$PWD/toolchain/neutron_18
PATH=$CLANG_DIR/bin:$PATH

# Check if toolchain exists
if [ ! -f "$CLANG_DIR/bin/clang-18" ]; then
    echo "-----------------------------------------------"
    echo "Toolchain not found! Downloading..."
    echo "-----------------------------------------------"
    rm -rf $CLANG_DIR
    mkdir -p $CLANG_DIR
    pushd toolchain/neutron_18 > /dev/null
    bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -S=05012024
    echo "-----------------------------------------------"
    echo "Patching toolchain..."
    echo "-----------------------------------------------"
    bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") --patch=glibc
    echo "-----------------------------------------------"
    echo "Cleaning up..."
    popd > /dev/null
fi

# OEM Setting
export ARCH=arm64
export PRODUCT_NAME=b2q
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# Cooking Kernel Source
MAKE_ARGS="
-j16 \
LLVM=1 \
LLVM_IAS=1 \
ARCH=arm64 \
CLANG_TRIPLE=aarch64-linux-gnu- \
$KERNEL_MAKE_ENV \
O=out
"

DEFCONFIG="vendor/b2q_kor_singlex_defconfig gorhanhee.config"

if [ "${KSU}" == "y" ]; then
    CONFIGS="${DEFCONFIG} kernelsu.config"
else
    CONFIGS="${DEFCONFIG}"
fi

make ${MAKE_ARGS} ${CONFIGS} || exit 1
make ${MAKE_ARGS} || exit 1