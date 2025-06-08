#!/bin/bash

# Configurações básicas
export ARCH=arm64
KERNEL_DIR=$(pwd)
OUT_DIR=${KERNEL_DIR}/out

# Criar diretório de saída
mkdir -p ${OUT_DIR}

# Caminhos dos toolchains
BUILD_CROSS_COMPILE=${KERNEL_DIR}/toolchain/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=${KERNEL_DIR}/toolchain/llvm-arm-toolchain-ship/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-

# Configurações do ambiente de build
KERNEL_MAKE_ENV="DTC_EXT=${KERNEL_DIR}/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

# CORREÇÃO: Usar o linker correto do toolchain ARM64
export PATH=${KERNEL_DIR}/toolchain/aarch64-linux-android-4.9/bin:$PATH
export LD=aarch64-linux-android-ld
export CROSS_COMPILE=$BUILD_CROSS_COMPILE
export CC=aarch64-linux-android-gcc
export CXX=aarch64-linux-android-g++

# Verificar se os toolchains existem
if [ ! -f "${BUILD_CROSS_COMPILE}gcc" ]; then
    echo "ERRO: Toolchain ARM64 não encontrado em ${BUILD_CROSS_COMPILE}gcc"
    exit 1
fi

if [ ! -f "$KERNEL_LLVM_BIN" ]; then
    echo "ERRO: Clang não encontrado em $KERNEL_LLVM_BIN"
    exit 1
fi

if [ ! -f "${BUILD_CROSS_COMPILE}ld" ]; then
    echo "ERRO: Linker ARM64 não encontrado em ${BUILD_CROSS_COMPILE}ld"
    exit 1
fi

echo "=== Configurando kernel ==="
make -j$(nproc) -C ${KERNEL_DIR} O=${OUT_DIR} \
    $KERNEL_MAKE_ENV \
    ARCH=arm64 \
    CROSS_COMPILE=$BUILD_CROSS_COMPILE \
    LD=aarch64-linux-android-ld \
    CC=aarch64-linux-android-gcc \
    CONFIG_SECTION_MISMATCH_WARN_ONLY=y \
    vendor/a23_eur_open_defconfig

if [ $? -ne 0 ]; then
    echo "ERRO: Falha na configuração do kernel"
    exit 1
fi

echo "=== Compilando kernel ==="
make -j$(nproc) -C ${KERNEL_DIR} O=${OUT_DIR} \
    $KERNEL_MAKE_ENV \
    ARCH=arm64 \
    CROSS_COMPILE=$BUILD_CROSS_COMPILE \
    LD=aarch64-linux-android-ld \
    CC=aarch64-linux-android-gcc \
    CONFIG_SECTION_MISMATCH_WARN_ONLY=y

if [ $? -ne 0 ]; then
    echo "ERRO: Falha na compilação do kernel"
    exit 1
fi

# Verificar se a imagem foi gerada
if [ -f "${OUT_DIR}/arch/arm64/boot/Image" ]; then
    echo "=== Copiando imagem do kernel ==="
    cp ${OUT_DIR}/arch/arm64/boot/Image ${KERNEL_DIR}/arch/arm64/boot/Image
    echo "Build concluído com sucesso!"
    echo "Imagem do kernel: ${KERNEL_DIR}/arch/arm64/boot/Image"
else
    echo "ERRO: Imagem do kernel não foi gerada"
    exit 1
fi