ARG UBINTU_VERSION="24.04"
ARG LLVM_VERSION="18"
FROM ubuntu:${DISTRO_IMAGE} AS base
ARG LLVM_VERSION
ARG UBUNTU_VERSION

ENV LLVM_VERSION=${LLVM_VERSION}

COPY . /workdir

CMD ["/workdir/build.sh"]

# ENV DEBIAN_FRONTEND=noninteractive

# RUN apt-get update && \
#     apt-get full-upgrade -y

# RUN echo "$(apt search gcc 2>/dev/null | grep -E -i '^gcc-([0-9]{2}/)' | awk -F'/' '{print $1}' | awk -F'-' '{print $2}' | sort -r | head -n1)" > /tmp/gcc_version

# RUN apt-get install -y \
#     --no-install-recommends \
#     gnupg \
#     curl \
#     wget \
#     git \
#     pkg-config \
#     build-essential \
#     gcc-$(cat /tmp/gcc_version) \
#     g++-$(cat /tmp/gcc_version) \
#     libcurl4-openssl-dev \
#     libxml2-dev \
#     libedit-dev \
#     zip \
#     unzip \
#     libzstd-dev \
#     zlib1g-dev \
#     cmake \
#     ninja-build \
#     automake \
#     autoconf \
#     autoconf-archive \
#     python3 \
#     python3-pip \
#     python3-setuptools

# ENV LVM_ROOT="/opt/llvm-${LLVM_VERSION}"

# RUN mkdir -p /tmp/llvm && cd /tmp/llvm && \
#     git clone --depth 1 --branch "release/${LLVM_VERSION}.x" https://github.com/llvm/llvm-project

# WORKDIR /tmp/llvm/llvm-project

# RUN cmake -S ./llvm -B build \
#     -DCMAKE_C_COMPILER="$(which gcc-$(cat /tmp/gcc_version))" \
#     -DCMAKE_CXX_COMPILER="$(which g++-$(cat /tmp/gcc_version))" \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_INSTALL_PREFIX=$LLVM_ROOT \
#     -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld;openmp" \
#     -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DLLVM_ENABLE_ASSERTIONS=OFF \
#     -DLLVM_TARGETS_TO_BUILD="AMDGPU;NVPTX;X86" \
#     -DCLANG_ANALYZER_ENABLE_Z3_SOLVER=0 \
#     -DLLVM_INCLUDE_BENCHMARKS=0 \
#     -DLLVM_INCLUDE_EXAMPLES=0 \
#     -DLLVM_INCLUDE_TESTS=0 \
#     -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
#     -DCMAKE_INSTALL_RPATH=$LLVM_ROOT/lib \
#     -DLLVM_ENABLE_OCAMLDOC=OFF \
#     -DLLVM_ENABLE_BINDINGS=OFF \
#     -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=OFF \
#     -DLLVM_BUILD_LLVM_DYLIB=ON \
#     -DLLVM_ENABLE_DUMP=OFF \
#     -DLLVM_PARALLEL_LINK_JOBS=1 \
#     -DLLVM_ENABLE_LTO=on \
#     -DLLVM_USE_SPLIT_DWARF=ON \
#     -DLLVM_OPTIMIZED_TABLEGEN=ON \
#     -DLLVM_ENABLE_RTTI=ON

# RUN cmake --build build
# RUN cmake --install build
