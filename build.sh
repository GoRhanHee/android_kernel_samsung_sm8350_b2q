#!/bin/bash

# submodule
git submodule init && git submodule update --remote

# Compiling Setting
export KSU=$1
export ANDROID_BUILD_TOP=$(pwd)

# Import Cross Compiler
git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9  \
 toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# Import clang-r383902
git clone https://github.com/UniversalX-devs/prebuilts_clang_host_linux-x86_clang-r383902.git \
 toolchain/clang/host/linux-x86/clang-r383902

# Setting toolchain path
CLANG_DIR=${ANDROID_BUILD_TOP}/toolchain/clang/host/linux-x86/clang-r383902
GCC_DIR=${ANDROID_BUILD_TOP}/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9
PATH=$CLANG_DIR/bin:$CLANG_DIR/lib:$GCC_DIR/bin:$GCC_DIR/lib:$PATH

# OEM Setting
export ARCH=arm64
export PRODUCT_NAME=b2q
export LINKER="ld.lld"

# Cooking Kernel Source
MAKE_ARGS="
-j16 \
LLVM=1 \
LLVM_IAS=1 \
ARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
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