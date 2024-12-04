ARG LLVM_BUILDER_TAG="ubuntu-24.04"
ARG LLVM_VERSION="18"
FROM smartcoder/llvm-clang:${LLVM_VERSION}-stage1-${LLVM_BUILDER_TAG} AS builder
ARG LLVM_VERSION

WORKDIR /tmp

RUN git clone --depth 1 --branch "release/${LLVM_VERSION}.x" https://github.com/llvm/llvm-project

ENV LLVM_ROOT="/opt/llvm-${LLVM_VERSION}"

WORKDIR /tmp/llvm-project

RUN cmake -S ./llvm -B build \
    -DCMAKE_C_COMPILER=${LLVM_ROOT_STAGE1}/bin/clang \
    -DCMAKE_CXX_COMPILER=${LLVM_ROOT_STAGE1}/bin/clang++ \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$LLVM_ROOT \
    -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
    -DCMAKE_INSTALL_RPATH=$LLVM_ROOT/lib \
    -DLLVM_ENABLE_OCAMLDOC=OFF \
    -DLLVM_ENABLE_BINDINGS=OFF \
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=OFF \
    -DLLVM_ENABLE_DUMP=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_ENABLE_LTO=on \
    -DLLVM_USE_SPLIT_DWARF=ON \
    -DLLVM_ENABLE_RTTI=ON

RUN cmake --build build
RUN cmake --install build

RUN rm -rf /tmp/llvm-project