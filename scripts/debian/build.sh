#!/bin/sh

set -x
set -e

# shellcheck source=/dev/null
. /etc/os-release

export DEBIAN_FRONTEND=noninteractive

apt update && apt full-upgrade -y

GCC_VERSION="$(apt search gcc 2>/dev/null | grep -E -i '^gcc-([0-9]{2}/)' | awk -F'/' '{print $1}' | awk -F'-' '{print $2}' | sort -r | head -n1)"
export GCC_VERSION

apt install -y --no-install-recommends \
    gnupg \
    curl \
    wget \
    git \
    pkg-config \
    build-essential \
    gcc-"$GCC_VERSION" \
    g++-"$GCC_VERSION" \
    libcurl4-openssl-dev \
    libxml2-dev \
    libedit-dev \
    zip \
    unzip \
    libzstd-dev \
    zlib1g-dev \
    cmake \
    ninja-build \
    automake \
    autoconf \
    autoconf-archive \
    python3 \
    python3-pip \
    python3-setuptools

mkdir -p /tmp/llvm && cd /tmp/llvm
git clone --depth 1 --branch "release/${LLVM_VERSION}.x" https://github.com/llvm/llvm-project

export LLVM_ROOT="/opt/adaptive-cpp/llvm-${LLVM_VERSION}"

## Build LLVM libc and libc++

cmake -S ./ -B build \
      -DCMAKE_C_COMPILER="$(which gcc)" \
      -DCMAKE_CXX_COMPILER="$(which g++)" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$LLVM_ROOT \
      -DLLVM_ENABLE_RUNTIMES="libc;libc++" \
      -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_ASSERTIONS=OFF \
      -DCLANG_ANALYZER_ENABLE_Z3_SOLVER=0 \
      -DLLVM_INCLUDE_BENCHMARKS=0 \
      -DLLVM_INCLUDE_EXAMPLES=0 \
      -DLLVM_INCLUDE_TESTS=0 \
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
      -DCMAKE_INSTALL_RPATH=$LLVM_ROOT/lib \
      -DLLVM_ENABLE_OCAMLDOC=OFF \
      -DLLVM_ENABLE_BINDINGS=OFF \
      -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=OFF \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_ENABLE_DUMP=OFF \
      -DLLVM_PARALLEL_LINK_JOBS=1 \
      -LLVM_ENABLE_LTO=Full \
      -DLLVM_USE_SPLIT_DWARF=ON \
      -DLLVM_OPTIMIZED_TABLEGEN=ON \
      -DLLVM_ENABLE_RTTI=ON

cmake --build build

cmake --install ./build
