#!/bin/bash

# submodule
git submodule init && git submodule update --remote

# Compiling Setting
export KSU=$1
export ANDROID_BUILD_TOP=$(pwd)

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9  \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import LLVM toolchain
git clone https://github.com/proprietary-stuff/llvm-arm-toolchain-ship-10.0 \
 toolchain/llvm-arm-toolchain-ship/10.0

# Setting toolchain path
CLANG_DIR=${ANDROID_BUILD_TOP}/toolchain/llvm-arm-toolchain-ship/10.0
GCC_DIR=${ANDROID_BUILD_TOP}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
PATH=$CLANG_DIR/bin:$CLANG_DIR/lib:$GCC_DIR/bin:$GCC_DIR/lib:$PATH

# OEM Setting
export ARCH=arm64
export PRODUCT_NAME=b2q
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# Cooking Kernel Source
MAKE_ARGS="
-j16 \
LLVM=1 \
LLVM_IAS=1 \
ARCH=arm64 \
READELF=$CLANG_DIR/bin/llvm-readelf \
CROSS_COMPILE=$GCC_DIR/bin/aarch64-linux-gnu- \
$KERNEL_MAKE_ENV \
CLANG_TRIPLE=aarch64-linux-gnu- \
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