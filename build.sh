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

mkdir out

# Cooking Kernel Source
MAKE_ARGS="
-j16 \
LLVM=1 \
ARCH=arm64 \
CC=clang \
CROSS_COMPILE=$CLANG_DIR/bin/llvm- \
CLANG_TRIPLE=$CLANG_DIR/bin/aarch64-linux-gnu- \
O=out
"

DEFCONFIG="vendor/b2q_kor_singlex_defconfig vendor/gorhanhee.config"

if [ "${KSU}" == "y" ]; then
    CONFIGS="${DEFCONFIG} vendor/kernelsu.config"
else
    CONFIGS="${DEFCONFIG}"
fi

make ${MAKE_ARGS} ${CONFIGS} || exit 1
make ${MAKE_ARGS} || exit 1

# Cooking Kernel module
export MODULE_DIR=${ANDROID_BUILD_TOP}/out/modules_out
make ${MAKE_ARGS} INSTALL_MOD_PATH=${MODULE_DIR} INSTALL_MOD_STRIP=1 modules_install || exit 1

# ***************** Cooking flashable files code **************************
mkdir prebuilts/output
chmod +x ${ANDROID_BUILD_TOP}/prebuilts/*

cd ${ANDROID_BUILD_TOP}/prebuilts

# Cooking dtbo.img
./mkdtimg cfg_create ${ANDROID_BUILD_TOP}/prebuilts/output/dtbo.img ${ANDROID_BUILD_TOP}/prebuilts/dtbo.cfg -d ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/dts/samsung/b2/b2q

# Cooking boot.img
unzip -jo ${ANDROID_BUILD_TOP}/prebuilts/boot.zip boot.img -d ${ANDROID_BUILD_TOP}/prebuilts/
./magiskboot unpack boot.img
cp ${ANDROID_BUILD_TOP}/out/arch/arm64/boot/Image ${ANDROID_BUILD_TOP}/prebuilts/kernel
./magiskboot repack boot.img
cp ${ANDROID_BUILD_TOP}/prebuilts/new-boot.img ${ANDROID_BUILD_TOP}/prebuilts/output/boot.img

# Copying patched vbmeta.img
cp ${ANDROID_BUILD_TOP}/prebuilts/vbmeta.img ${ANDROID_BUILD_TOP}/prebuilts/output/vbmeta.img

# Cooking flashable file
cd ${ANDROID_BUILD_TOP}/prebuilts/output
tar -cvf "F711N_KSUN_Odin.tar" boot.img dtbo.img vbmeta.img

# ***************** Cooking flashable files code **************************