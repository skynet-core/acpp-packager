# AdaptiveCpp Docker Packager

## Build base builder

        docker build --build-arg=TAG=24.04 \
            -t smartcoder/llvm-builder-base:ubuntu-24.04 . -f .\base\Dockerfile.ubuntu
        docker push smartcoder/llvm-builder-base:ubuntu-24.04

## Build Clang stage1 linked against libstdc++

        docker build -t smartcoder/llvm-clang:18-stage1-ubuntu24.04 \
            --build-arg=LLVM_BUILDER_TAG=ubuntu-24.04 \
            --build-arg=LLVM_VERSION=18 . -f .\llvm\clang\Dockerfile.stage1
        
        docker push smartcoder/llvm-clang:18-stage1-ubuntu24.04

## Build LLVM libc and libc++ using clang
