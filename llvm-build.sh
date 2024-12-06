#!/bin/bash

set -e

UNATTENDED_INSTALL=1
while getopts "ib" opt; do
    case $opt in
    i)
        UNATTENDED_INSTALL=0
        ;;
    b)
        FORCE_BINUTILS=1
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
done

export DEBIAN_FRONTEND=noninteractive

HALF_CPUS=$(($(nproc) / 2))

### colors
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
LIGHTBLUE='\033[1;34m'
_NC='\033[0m' # No Color
red_msg() {
    echo -n -e "${RED}$1${_NC}"
}
green_msg() {
    echo -n -e "${GREEN}$1${_NC}"
}
orange_msg() {
    echo -n -e "${ORANGE}$1${_NC}"
}
blue_msg() {
    echo -n -e "${BLUE}$1${_NC}"
}
purple_msg() {
    echo -n -e "${PURPLE}$1${_NC}"
}
cyan_msg() {
    echo -n -e "${CYAN}$1${_NC}"
}
yellow_msg() {
    echo -n -e "${CYAN}$1${_NC}"
}

u_prompt() {
    msg_=$1
    shift
    def_=$1
    shift
    unset REPLY
    if [ -z "$UNATTENDED_INSTALL" ] || [ "$UNATTENDED_INSTALL" -eq 0 ]; then
        PROMPT_COUNTER=$(get_cache_or_default "PROMPT_COUNTER" "0")
        mod_=$((PROMPT_COUNTER % 2))
        color_print="green_msg"
        if [ "$mod_" -eq 0 ]; then
            color_print="purple_msg"
        fi
        read -p "$("$color_print" "$msg_")" -r $@
        PROMPT_COUNTER=$((PROMPT_COUNTER + 1))
        set_cache "PROMPT_COUNTER" "$PROMPT_COUNTER"
    fi
    if [[ -z "$REPLY" ]]; then
        REPLY="$def_"
    fi
    echo "$REPLY"
}

spinner() {
    secs="$1"
    while [ $secs -gt 0 ]; do
        sleep 0.2
        echo -n "."
        secs=$((secs - 1))
    done
    echo
}

dots_message() {
    color_=$1
    shift
    dots_=$1
    shift
    echo -n -e "${color_}"
    echo -n -e "$@"
    spinner $dots_
    echo -n -e "${_NC}\n"
}

CACHE_FILE="build.cache"

get_cache() {
    res="$(cat "$CACHE_FILE" 2>/dev/null | grep "$1" | tail -n1 | cut -d'=' -f2)"
    if [ -z "$res" ]; then
        UNATTENDED_INSTALL=0
    fi
    echo "$res"
}

set_cache() {
    if [ ! -f "$CACHE_FILE" ]; then
        touch "$CACHE_FILE"
        echo "$1=$2" >>"$CACHE_FILE"
        return 0
    fi
    old=$(get_cache "$1")
    if [ -n "$old" ]; then
        sed -i "s|$1=.*|$1=$2|g" "$CACHE_FILE"
    else
        echo "$1=$2" >>"$CACHE_FILE"
    fi
    return 0
}

get_cache_or_default() {
    key_=$1
    default_=$2
    value_=$(get_cache "$key_")
    if [ -z "$value_" ]; then
        value_="$default_"
    fi
    echo "$value_"
}

#!/bin/bash

extract_progress() {
    while IFS= read -r line; do
        if [[ $line =~ ([0-9]+)% ]]; then
            echo "Progress: ${BASH_REMATCH[1]}%"
        fi
    done
}

_rand() {
    openssl rand -hex "$1"
}

UPGRADE_SYSTEM=$(get_cache_or_default "UPGRADE_SYSTEM" "y")
UPGRADE_SYSTEM=$(u_prompt "Do you want to update the system? [y/N] (default: $UPGRADE_SYSTEM) " "$UPGRADE_SYSTEM" -n 1)
echo
set_cache "UPGRADE_SYSTEM" "$UPGRADE_SYSTEM"
if [[ $UPGRADE_SYSTEM =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Update the system"
    apt-get -qq update
    apt-get -qq full-upgrade -y
fi

CXX_STD="$(get_cache_or_default "CXX_STD" "20")"
CXX_STD="$(u_prompt "What C++ standard do you want to use [17/20/23]? (default: $CXX_STD) " "$CXX_STD" -n 2)"
echo
set_cache "CXX_STD" "$CXX_STD"

GCC_VERSION="$(get_cache_or_default "GCC_VERSION" "13")"
GCC_VERSION="$(u_prompt "What GCC version do you want to use [13/14]? (default: $GCC_VERSION) " "$GCC_VERSION" -n 2)"
echo
set_cache "GCC_VERSION" "$GCC_VERSION"

INSTALL_REQUIRED_PACKAGES="$(get_cache_or_default "INSTALL_REQUIRED_PACKAGES" "y")"
INSTALL_REQUIRED_PACKAGES="$(u_prompt "Do you want to install the required packages? [y/N] (default: $INSTALL_REQUIRED_PACKAGES) " "$INSTALL_REQUIRED_PACKAGES" -n 1)"
echo
set_cache "INSTALL_REQUIRED_PACKAGES" "$INSTALL_REQUIRED_PACKAGES"
if [[ $INSTALL_REQUIRED_PACKAGES =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Install the required packages"
    apt-get -qq install -y \
        --no-install-recommends \
        gnupg \
        curl \
        wget \
        git \
        pkg-config \
        build-essential \
        "gcc-$GCC_VERSION" \
        "g++-$GCC_VERSION" \
        libcurl4-openssl-dev \
        libxml2-dev \
        libedit-dev \
        binutils-dev \
        zip \
        unzip \
        libzstd-dev \
        zlib1g-dev \
        cmake \
        ninja-build \
        automake \
        autoconf \
        hwloc \
        autoconf-archive \
        python3 \
        python3-pip \
        python3-setuptools \
        swig \
        liblzma-dev \
        libmpfr-dev \
        libgmp-dev \
        texinfo \
        bison \
        flex \
        libtool \
        openssl \
        libelf-dev \
        libmpc-dev \
        libisl-dev \
        ccache \
        python3-dev
fi

BINUTILS_SOURCE_DIR="$(get_cache_or_default "BINUTILS_SOURCE_DIR" "/tmp/binutils")"
BINUTILS_PREFIX_DEFAULT="$(get_cache_or_default "BINUTILS_PREFIX" "/opt/binutils")"
BINUTILS_PREFIX="$(get_cache_or_default "BINUTILS_PREFIX" "")"

if [ -n "$FORCE_BINUTILS" ] && [ "$FORCE_BINUTILS" -eq 1 ]; then
    BUILD_BINUTILS_GDB=$(get_cache_or_default "BUILD_BINUTILS_GDB" "y")
    BUILD_BINUTILS_GDB="$(u_prompt "Do you want to use binutils-gdb? [y/N] (default: $BUILD_BINUTILS_GDB) " "$BUILD_BINUTILS_GDB" -n 1)"
    echo
    set_cache "BUILD_BINUTILS_GDB" "$BUILD_BINUTILS_GDB"
    if [[ $BUILD_BINUTILS_GDB =~ ^[Yy]$ ]]; then
        BINUTILS_SOURCE_DIR="$(u_prompt "Where do I have to look for binutils-gdb source code? (default: $BINUTILS_SOURCE_DIR) " "$BINUTILS_SOURCE_DIR")"
        echo
        set_cache "BINUTILS_SOURCE_DIR" "$BINUTILS_SOURCE_DIR"

        if [ ! -d "$BINUTILS_SOURCE_DIR" ]; then
            WANT_DOWNLOAD_BINUTILS_GDB=$(get_cache_or_default "WANT_DOWNLOAD_BINUTILS_GDB" "y")
            WANT_DOWNLOAD_BINUTILS_GDB="$(u_prompt "Download binutils source code? [y/N] (default: $WANT_DOWNLOAD_BINUTILS_GDB) " "$WANT_DOWNLOAD_BINUTILS_GDB" -n 1)"
            echo
            set_cache "WANT_DOWNLOAD_BINUTILS_GDB" "$WANT_DOWNLOAD_BINUTILS_GDB"
        else
            WANT_UPDATE_BINUTILS_GDB=$(get_cache_or_default "WANT_UPDATE_BINUTILS_GDB" "y")
            WANT_UPDATE_BINUTILS_GDB="$(u_prompt "Update binutils-gdb source code? [y/N] (default $WANT_UPDATE_BINUTILS_GDB) " "$WANT_UPDATE_BINUTILS_GDB" -n 1)"
            echo
            set_cache "WANT_UPDATE_BINUTILS_GDB" "$WANT_UPDATE_BINUTILS_GDB"
        fi
        if [[ $WANT_DOWNLOAD_BINUTILS_GDB =~ ^[Yy]$ ]] || [[ $WANT_UPDATE_BINUTILS_GDB =~ ^[Yy]$ ]]; then
            rm -rf "$BINUTILS_SOURCE_DIR"
            dots_message 6 "Download binutils-gdb source code to ${BINUTILS_SOURCE_DIR}"
            git clone --depth 1 --branch master \
                "https://sourceware.org/git/binutils-gdb.git" "$BINUTILS_SOURCE_DIR"
        fi

        WANT_CONFIGURE_BINUTILS_GDB=$(get_cache_or_default "WANT_CONFIGURE_BINUTILS_GDB" "y")
        WANT_CONFIGURE_BINUTILS_GDB="$(u_prompt "Configure binutils-gdb? [y/N] (default: $WANT_CONFIGURE_BINUTILS_GDB) " "$WANT_CONFIGURE_BINUTILS_GDB" -n 1)"
        echo
        set_cache "WANT_CONFIGURE_BINUTILS_GDB" "$WANT_CONFIGURE_BINUTILS_GDB"
        if [[ $WANT_CONFIGURE_BINUTILS_GDB =~ ^[Yy]$ ]]; then
            BINUTILS_PREFIX="$(u_prompt "Where do you want to install binutils-gdb? (default: $BINUTILS_PREFIX_DEFAULT) " "$BINUTILS_PREFIX_DEFAULT")"
            echo
            set_cache "BINUTILS_PREFIX" "$BINUTILS_PREFIX"
            dots_message "$CYAN" 6 "Configure binutils-gdb"

            mkdir -p "/tmp/binutils-build"
            cd "/tmp/binutils-build"
            CC="/usr/bin/gcc-$GCC_VERSION" \
                CXX="/usr/bin/g++-$GCC_VERSION" \
                CFLAGS="-O3 -fPIC -march=native -flto -ffast-math" \
                ../binutils/configure --prefix=$BINUTILS_PREFIX --enable-gold --enable-plugins --disable-werror \
                --with-gmp --with-mpfr --with-mpc --with-isl --with-libelf --with-lzma --with-zstd \
                --enable-gold=default --enable-lto --enable-threads --enable-64-bit-bfd
        fi
        WANT_COMPILE_BINUTILS_GDB=$(get_cache_or_default "WANT_COMPILE_BINUTILS_GDB" "y")
        WANT_COMPILE_BINUTILS_GDB="$(u_prompt "Compile binutils-gdb? [y/N] (default: $WANT_COMPILE_BINUTILS_GDB) " "$WANT_COMPILE_BINUTILS_GDB" -n 1)"
        echo
        set_cache "WANT_COMPILE_BINUTILS_GDB" "$WANT_COMPILE_BINUTILS_GDB"
        if [[ $WANT_COMPILE_BINUTILS_GDB =~ ^[Yy]$ ]]; then
            dots_message "$CYAN" 6 "Compile binutils-gdb"
            make -j"$HALF_CPUS" all-gold
        fi

        WANT_INSTALL_BINUTILS_GDB=$(get_cache_or_default "WANT_INSTALL_BINUTILS_GDB" "y")
        WANT_INSTALL_BINUTILS_GDB="$(u_prompt "Install binutils-gdb? [y/N] (default: $WANT_INSTALL_BINUTILS_GDB) " "$WANT_INSTALL_BINUTILS_GDB" -n 1)"
        echo
        set_cache "WANT_INSTALL_BINUTILS_GDB" "$WANT_INSTALL_BINUTILS_GDB"
        if [[ $WANT_INSTALL_BINUTILS_GDB =~ ^[Yy]$ ]]; then
            dots_message "$CYAN" 6 "Install binutils-gdb"
            make install-gold
        fi

        WANT_SYMLINK_BINUTILS_GDB=$(get_cache_or_default "WANT_SYMLINK_BINUTILS_GDB" "y")
        WANT_SYMLINK_BINUTILS_GDB="$(u_prompt "Symbolic to ld.gold? [y/N] (default: $WANT_SYMLINK_BINUTILS_GDB) " "$WANT_SYMLINK_BINUTILS_GDB" -n 1)"
        echo
        set_cache "WANT_SYMLINK_BINUTILS_GDB" "$WANT_SYMLINK_BINUTILS_GDB"
        if [[ $WANT_SYMLINK_BINUTILS_GDB =~ ^[Yy]$ ]]; then
            yellow_msg "Symbolic link ld.gold to /usr/bin/ld.gold\n"
            ln -sf "$BINUTILS_PREFIX/bin/ld.gold" /usr/bin/ld.gold
        fi
    fi
fi

LLVM_VERSION="$(get_cache_or_default "LLVM_VERSION" "18.1.8")"
LLVM_VERSION="$(u_prompt "What LLVM version do you want to use? (default: $LLVM_VERSION) " "$LLVM_VERSION")"
echo
set_cache "LLVM_VERSION" "$LLVM_VERSION"

# LLVM_MAJOR_VERSION="$(echo "$LLVM_VERSION" | cut -d. -f1)"
# LLVM_MINOR_VERSION="$(echo "$LLVM_VERSION" | cut -d. -f2)"
# LLVM_PATCH_VERSION="$(echo "$LLVM_VERSION" | cut -d. -f3)"

LLVM_SOURCE_DIR=$(get_cache_or_default "LLVM_SOURCE_DIR" "/tmp/llvm-project")
LLVM_SOURCE_DIR="$(u_prompt "Where do you want to download the LLVM source code? (default: $LLVM_SOURCE_DIR) " "$LLVM_SOURCE_DIR")"
echo
set_cache "LLVM_SOURCE_DIR" "$LLVM_SOURCE_DIR"

WANT_DOWNLOAD_LLVM=$(get_cache_or_default "WANT_DOWNLOAD_LLVM" "y")
WANT_DOWNLOAD_LLVM="$(u_prompt "Download the LLVM source code? [y/N] (default: $WANT_DOWNLOAD_LLVM) " "$WANT_DOWNLOAD_LLVM" -n 1)"
echo
set_cache "WANT_DOWNLOAD_LLVM" "$WANT_DOWNLOAD_LLVM"
if [[ $WANT_DOWNLOAD_LLVM =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Download the LLVM source code to ${LLVM_SOURCE_DIR}"
    if [ -d "$LLVM_SOURCE_DIR" ]; then
        rm -rf "$LLVM_SOURCE_DIR"
    fi
    git clone --depth 1 --branch "llvmorg-${LLVM_VERSION}" \
        "https://github.com/llvm/llvm-project" "$LLVM_SOURCE_DIR"
fi

LLVM_BOOTSTRAP_PREFIX=$(get_cache_or_default "LLVM_BOOTSTRAP_PREFIX" "/opt/llvm-${LLVM_VERSION}-bootstrap")
LLVM_BOOTSTRAP_PREFIX="$(u_prompt "Where do you want to install the LLVM stage 1 toolchain? (default: $LLVM_BOOTSTRAP_PREFIX) " "$LLVM_BOOTSTRAP_PREFIX")"
echo
set_cache "LLVM_BOOTSTRAP_PREFIX" "$LLVM_BOOTSTRAP_PREFIX"

LLVM_BUILD_DIR="$(get_cache_or_default "LLVM_BUILD_DIR" "/tmp/llvm-${LLVM_VERSION}-build")"

WANT_CONFIGURE_STAGE1=$(get_cache_or_default "WANT_CONFIGURE_STAGE1" "y")
WANT_CONFIGURE_STAGE1="$(u_prompt "Do you want to configure the stage 1 toolchain? [y/N] (default: $WANT_CONFIGURE_STAGE1) " "$WANT_CONFIGURE_STAGE1" -n 1)"
echo
set_cache "WANT_CONFIGURE_STAGE1" "$WANT_CONFIGURE_STAGE1"
if [[ $WANT_CONFIGURE_STAGE1 =~ ^[Yy]$ ]]; then

    LLVM_ENABLE_LTO="$(get_cache_or_default "LLVM_ENABLE_LTO" "OFF")"
    LLVM_ENABLE_LTO="$(u_prompt "Do you want to enable LTO? [ON/OFF] (default: ${LLVM_ENABLE_LTO}) " "OFF")"
    echo
    set_cache "ENABLE_LTO" "$LLVM_ENABLE_LTO"

    LLVM_USE_LINKER="$(get_cache_or_default "LLVM_USE_LINKER" "gold")"
    LLVM_USE_LINKER="$(u_prompt "Linker to use? [gold/ld] (default: ${LLVM_USE_LINKER}) " "gold")"
    echo
    set_cache "LLVM_USE_LINKER" "$LLVM_USE_LINKER"

    if [ -d "$LLVM_BUILD_DIR" ]; then
        REMOVE_STAGE1_BUILDIR=$(get_cache_or_default "REMOVE_STAGE1_BUILDIR" "n")
        REMOVE_STAGE1_BUILDIR="$(u_prompt "Remove ${LLVM_BUILD_DIR} dir? [y/N] (default: $REMOVE_STAGE1_BUILDIR)" "$REMOVE_STAGE1_BUILDIR" -n 1)"
        echo
        set_cache "REMOVE_STAGE1_BUILDIR" "$REMOVE_STAGE1_BUILDIR"
        if [[ $REMOVE_STAGE1_BUILDIR =~ ^[Yy]$ ]]; then
            rm -rf "$LLVM_BUILD_DIR"
        fi
    fi
    dots_message "$CYAN" 6 "Configure the stage 1 toolchain"

    CMAKE_OPTIONS=(
        -G
        Ninja
        -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt"
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind"
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_C_COMPILER="/usr/bin/gcc-$GCC_VERSION"
        -DCMAKE_CXX_COMPILER="/usr/bin/g++-$GCC_VERSION"
        -DCMAKE_CXX_FLAGS="-fPIC -march=native -ffast-math -fexceptions -Wno-deprecated"
        -DCMAKE_CXX_STANDARD="$CXX_STD"
        -DCMAKE_CXX_STANDARD_REQUIRED=ON
        -DCMAKE_CXX_EXTENSIONS=OFF
        -DCMAKE_INSTALL_PREFIX="${LLVM_BOOTSTRAP_PREFIX}"
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
        -DCMAKE_INSTALL_RPATH="${LLVM_BOOTSTRAP_PREFIX}/lib"
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
        -DLIBCXX_ENABLE_STATIC=ON \
        -DLIBCXX_USE_COMPILER_RT=ON \
        -DLIBCXXABI_ENABLE_STATIC=ON \
        -DLIBCXXABI_USE_COMPILER_RT=ON \
        -DLLVM_RAM_PER_LINK_JOB=10000
        -DLLVM_BUILD_LLVM_DYLIB=ON
        -DLLVM_ENABLE_RTTI=ON
        -DLLVM_ENABLE_EH=ON
        -DLLVM_ENABLE_THREADS=ON
        -DLLVM_INSTALL_UTILS=ON
        -DLLVM_ENABLE_LTO="${LLVM_ENABLE_LTO}"
        -DLLVM_USE_LINKER="${LLVM_USE_LINKER}"
        -DLLVM_USE_SPLIT_DWARF=ON
        -DLLVM_ENABLE_PIC=ON
        -DLLVM_CCACHE_BUILD=ON
        -DLLVM_TARGETS_TO_BUILD="X86"
        -B
        "$LLVM_BUILD_DIR"
        -S
        "$LLVM_SOURCE_DIR/llvm"
    )

    if [ -n "$BINUTILS_PREFIX" ]; then
        CMAKE_OPTIONS+=("-DLLVM_BINUTILS_INCDIR=$BINUTILS_PREFIX/include")
    fi
    cmake "${CMAKE_OPTIONS[@]}" --fresh
fi

WANT_TO_COMPILE_STAGE1=$(get_cache_or_default "WANT_TO_COMPILE_STAGE1" "y")
WANT_TO_COMPILE_STAGE1="$(u_prompt "Compile the stage 1 toolchain? [y/N] (default: $WANT_TO_COMPILE_STAGE1) " "$WANT_TO_COMPILE_STAGE1" -n 1)"
echo
set_cache "WANT_TO_COMPILE_STAGE1" "$WANT_TO_COMPILE_STAGE1"
if [[ $WANT_TO_COMPILE_STAGE1 =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Compile the stage 1 toolchain"
    cmake --build "$LLVM_BUILD_DIR" --parallel "$HALF_CPUS"
fi

WANT_TO_INSTALL_STAGE1=$(get_cache_or_default "WANT_TO_INSTALL_STAGE1" "y")
WANT_TO_INSTALL_STAGE1="$(u_prompt "Install the stage 1 toolchain? [y/N] (default: $WANT_TO_INSTALL_STAGE1) " "$WANT_TO_INSTALL_STAGE1" -n 1)"
echo
set_cache "WANT_TO_INSTALL_STAGE1" "$WANT_TO_INSTALL_STAGE1"
if [[ $WANT_TO_INSTALL_STAGE1 =~ ^[Yy]$ ]]; then
    rm -rf /opt/llvm-${LLVM_VERSION}
    dots_message "$CYAN" 6 "Install the stage 1 toolchain"
    cmake --install "$LLVM_BUILD_DIR"
fi

LD_LIBRARY_PATH="${LLVM_BOOTSTRAP_PREFIX}/lib:${LLVM_BOOTSTRAP_PREFIX}/lib/x86_64-unknown-linux-gnu:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

WANT_TO_INSTALL_STAGE1=$(get_cache_or_default "WANT_TO_INSTALL_STAGE1" "y")
WANT_TO_INSTALL_STAGE1="$(u_prompt "Install the stage 1 toolchain? [y/N] (default: $WANT_TO_INSTALL_STAGE1) " "$WANT_TO_INSTALL_STAGE1" -n 1)"
echo
set_cache "WANT_TO_INSTALL_STAGE1" "$WANT_TO_INSTALL_STAGE1"
if [[ $WANT_TO_INSTALL_STAGE1 =~ ^[Yy]$ ]]; then
    CUDA_VERSION_MAJOR="$(get_cache_or_default "CUDA_VERSION_MAJOR" "12")"
    CUDA_VERSION_MAJOR="$(u_prompt "CUDA Toolkit version [11/12]? (default: $CUDA_VERSION_MAJOR) " "$CUDA_VERSION_MAJOR" -n2)"
    echo
    set_cache "CUDA_VERSION_MAJOR" "$CUDA_VERSION_MAJOR"

    dots_message "$CYAN" 6 "Install CUDA Toolkit"
    cd /tmp
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    apt-get update
    apt-get install -y "cuda-toolkit-$CUDA_VERSION_MAJOR"
fi

WANT_ONETBB=$(get_cache_or_default "WANT_ONETBB" "n")
WANT_ONETBB="$(u_prompt "Install oneTBB? [y/N] (default: $WANT_ONETBB) " "$WANT_ONETBB" -n 1)"
echo
set_cache "WANT_ONETBB" "$WANT_ONETBB"
if [[ $WANT_ONETBB =~ ^[Yy]$ ]]; then
    ONE_TBB_VERSION="$(get_cache_or_default "ONE_TBB_VERSION" "2022.0.0")"
    ONE_TBB_VERSION="$(u_prompt "Enter oneTBB version? (default: $ONE_TBB_VERSION) " "$ONE_TBB_VERSION")"
    echo
    set_cache "ONE_TBB_VERSION" "$ONE_TBB_VERSION"

    ONETBB_SOURCE_DIR="$(get_cache_or_default "ONETBB_SOURCE_DIR" "/tmp/oneTBB-$ONE_TBB_VERSION")"
    ONETBB_SOURCE_DIR="$(u_prompt "oneTBB source dir? (default: $ONETBB_SOURCE_DIR) " "$ONETBB_SOURCE_DIR")"
    echo
    set_cache "ONETBB_SOURCE_DIR" "$ONETBB_SOURCE_DIR"

    if [ -d "$ONETBB_SOURCE_DIR" ]; then
        REMOVE_ONETBB_SOURCE_DIR=$(get_cache_or_default "REMOVE_ONETBB_SOURCE_DIR" "n")
        REMOVE_ONETBB_SOURCE_DIR="$(u_prompt "$ONETBB_SOURCE_DIR exists, remove? [y/N] (default: $REMOVE_ONETBB_SOURCE_DIR) " "$REMOVE_ONETBB_SOURCE_DIR" -n 1)"
        echo
        set_cache "REMOVE_ONETBB_SOURCE_DIR" "$REMOVE_ONETBB_SOURCE_DIR"
        if [[ $REMOVE_ONETBB_SOURCE_DIR =~ ^[Yy]$ ]]; then
            rm -rf "$ONETBB_SOURCE_DIR"
        fi
    fi

    dots_message "$CYAN" 6 "Download oneTBB source code"
    git clone --depth 1 \
        --branch "v2022.0.0" \
        "https://github.com/uxlfoundation/oneTBB.git" "$ONETBB_SOURCE_DIR"

    ONETBB_BUILD_DIR="$(get_cache_or_default "ONETBB_BUILD_DIR" "/tmp/oneTBB-$ONE_TBB_VERSION-build")"
    ONETBB_BUILD_DIR="$(u_prompt "oneTBB build dir? (default: $ONETBB_BUILD_DIR) " "$ONETBB_BUILD_DIR")"
    echo
    set_cache "ONETBB_BUILD_DIR" "$ONETBB_BUILD_DIR"

    if [ -d "$ONETBB_BUILD_DIR" ]; then
        REMOVE_ONETBB_BUILD_DIR=$(get_cache_or_default "REMOVE_ONETBB_BUILD_DIR" "n")
        REMOVE_ONETBB_BUILD_DIR="$(u_prompt "$ONETBB_BUILD_DIR exists, remove? [y/N] (default: $REMOVE_ONETBB_BUILD_DIR) " "$REMOVE_ONETBB_BUILD_DIR" -n 1)"
        echo
        set_cache "REMOVE_ONETBB_BUILD_DIR" "$REMOVE_ONETBB_BUILD_DIR"
        if [[ $REMOVE_ONETBB_BUILD_DIR =~ ^[Yy]$ ]]; then
            rm -rf "$ONETBB_BUILD_DIR"
        fi
    fi

    WANT_TO_CONFIGURE_ONETBB=$(get_cache_or_default "WANT_TO_CONFIGURE_ONETBB" "y")
    WANT_TO_CONFIGURE_ONETBB="$(u_prompt "Configure oneTBB? [y/N] (default: $WANT_TO_CONFIGURE_ONETBB) " "$WANT_TO_CONFIGURE_ONETBB" -n 1)"
    echo
    set_cache "WANT_TO_CONFIGURE_ONETBB" "$WANT_TO_CONFIGURE_ONETBB"
    if [[ $WANT_TO_CONFIGURE_ONETBB =~ ^[Yy]$ ]]; then
        ONETBB_INSTALL_PREFIX="$(get_cache_or_default "ONETBB_INSTALL_PREFIX" "/opt/oneTBB")"
        ONETBB_INSTALL_PREFIX="$(u_prompt "oneTBB install path? (default: $ONETBB_INSTALL_PREFIX) " "$ONETBB_INSTALL_PREFIX")"
        echo
        set_cache "ONETBB_INSTALL_PREFIX" "$ONETBB_INSTALL_PREFIX"

        dots_message "$CYAN" 6 "Configure oneTBB"
        cmake -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$ONETBB_INSTALL_PREFIX" \
            -S"$ONETBB_SOURCE_DIR" \
            -B"$ONETBB_BUILD_DIR" \
            --fresh
    fi

    WANT_TO_BUILD_ONETBB=$(get_cache_or_default "WANT_TO_BUILD_ONETBB" "y")
    WANT_TO_BUILD_ONETBB="$(u_prompt "Build oneTBB? [y/N] (default: $WANT_TO_BUILD_ONETBB) " "$WANT_TO_BUILD_ONETBB" -n 1)"
    echo
    set_cache "WANT_TO_BUILD_ONETBB" "$WANT_TO_BUILD_ONETBB"
    if [[ $WANT_TO_BUILD_ONETBB =~ ^[Yy]$ ]]; then
        dots_message "$CYAN" 6 "Build oneTBB"
        cmake --build "$ONETBB_BUILD_DIR" --parallel "$HALF_CPUS"
    fi

    WANT_TO_INSTALL_ONETBB=$(get_cache_or_default "WANT_TO_INSTALL_ONETBB" "y")
    WANT_TO_INSTALL_ONETBB="$(u_prompt "Install oneTBB? [y/N] (default: $WANT_TO_INSTALL_ONETBB) " "$WANT_TO_INSTALL_ONETBB" -n 1)"
    echo
    set_cache "WANT_TO_INSTALL_ONETBB" "$WANT_TO_INSTALL_ONETBB"
    if [[ $WANT_TO_INSTALL_ONETBB =~ ^[Yy]$ ]]; then
        dots_message "$CYAN" 6 "Install oneTBB"
        cmake --install "$ONETBB_BUILD_DIR"
    fi
fi

LD_LIBRARY_PATH="${ONETBB_INSTALL_PREFIX}/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

LLVM_PROD_BUILD_DIR="$(get_cache_or_default "LLVM_PROD_BUILD_DIR" "/tmp/llvm-${LLVM_VERSION}-prod-build")"
LLVM_PROD_BUILD_DIR="$(u_prompt "Build dir for LLVM? (default: $LLVM_PROD_BUILD_DIR) " "$LLVM_PROD_BUILD_DIR")"
echo
set_cache "LLVM_PROD_BUILD_DIR" "$LLVM_PROD_BUILD_DIR"

WANT_TO_CONFIGURE_LLVM_PROD=$(get_cache_or_default "WANT_TO_CONFIGURE_LLVM_PROD" "y")
WANT_TO_CONFIGURE_LLVM_PROD="$(u_prompt "Configure LLVM? [y/N] (default: $WANT_TO_CONFIGURE_LLVM_PROD) " "$WANT_TO_CONFIGURE_LLVM_PROD" -n 1)"
echo
set_cache "WANT_TO_CONFIGURE_LLVM_PROD" "$WANT_TO_CONFIGURE_LLVM_PROD"
if [[ $WANT_TO_CONFIGURE_LLVM_PROD =~ ^[Yy]$ ]]; then

    LLVM_PREFIX="$(get_cache_or_default "LLVM_PREFIX" "/opt/llvm-${LLVM_VERSION}")"
    LLVM_PREFIX="$(u_prompt "Install path for LLVM? (default: $LLVM_PREFIX) " "$LLVM_PREFIX")"
    echo
    set_cache "LLVM_PREFIX" "$LLVM_PREFIX"

    MARCH="$(get_cache_or_default "MARCH" "znver3")"
    MARCH="$(u_prompt "What is your CPU microarchitecture? [znver3/core-avx2/core-avx-i] (default: $MARCH) " "$MARCH")"
    echo
    set_cache "MARCH" "$MARCH"

    LLVM_PROD_ENABLE_LTO="$(get_cache_or_default "LLVM_PROD_ENABLE_LTO" "full")"
    LLVM_PROD_ENABLE_LTO="$(u_prompt "Enable LTO? [off/on/thin/full] (default: ${LLVM_PROD_ENABLE_LTO}) " "$LLVM_PROD_ENABLE_LTO")"
    echo
    set_cache "LLVM_PROD_ENABLE_LTO" "$LLVM_PROD_ENABLE_LTO"

    if [ -d "$LLVM_PROD_BUILD_DIR" ]; then
        REMOVE_EXISTING_BUILD_DIR=$(get_cache_or_default "REMOVE_EXISTING_BUILD_DIR" "n")
        REMOVE_EXISTING_BUILD_DIR="$(u_prompt "Remove the existing ${LLVM_PROD_BUILD_DIR}? [y/N] (default: $REMOVE_EXISTING_BUILD_DIR) " "$REMOVE_EXISTING_BUILD_DIR" -n 1)"
        echo
        set_cache "REMOVE_EXISTING_BUILD_DIR" "$REMOVE_EXISTING_BUILD_DIR"
        if [[ $REMOVE_EXISTING_BUILD_DIR =~ ^[Yy]$ ]]; then
            rm -rf "$LLVM_PROD_BUILD_DIR"
        fi
    fi

    # /tmp/llvm-project/llvm/include/llvm/CodeGen/ByteProvider.h:32:43:
    # #include <bits/stdint-intn.h>'

    dots_message "$CYAN" 6 "Configure LLVM"
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${LLVM_PREFIX}" \
        -DCMAKE_C_COMPILER="${LLVM_BOOTSTRAP_PREFIX}/bin/clang" \
        -DCMAKE_CXX_COMPILER="${LLVM_BOOTSTRAP_PREFIX}/bin/clang++" \
        -DCMAKE_CXX_STANDARD="$CXX_STD" \
        -DCMAKE_CXX_STANDARD_REQUIRED="ON" \
        -DCMAKE_CXX_EXTENSIONS="OFF" \
        -DCMAKE_CXX_FLAGS="-Wno-unused-command-line-argument -Wno-deprecated-this-capture -stdlib=libc++ -march=$MARCH -fvisibility=hidden -include utility -fexceptions -rtlib=compiler-rt -lc -lm -lc++ -lc++abi -lunwind" \
        -DCMAKE_EXE_LINKER_FLAGS="-L${LLVM_BOOTSTRAP_PREFIX}/lib -L${LLVM_BOOTSTRAP_PREFIX}/lib/clang/18/lib/x86_64-unknown-linux-gnu -L${LLVM_BOOTSTRAP_PREFIX}/lib/x86_64-unknown-linux-gnu" \
        -DCMAKE_LINKER="${LLVM_BOOTSTRAP_PREFIX}/bin/ld.lld" \
        -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
        -DCMAKE_INSTALL_RPATH="${LLVM_PREFIX}/lib" \
        -DLLVM_TARGETS_TO_BUILD="AMDGPU;NVPTX;X86" \
        -DLLVM_USE_SPLIT_DWARF="ON" \
        -DLLVM_USE_LINKER="lld" \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_ENABLE_LTO="${LLVM_PROD_ENABLE_LTO}" \
        -DLLVM_ENABLE_MODULES=ON \
        -DLLVM_ENABLE_EH=ON \
        -DLLVM_ENABLE_THREADS=ON \
        -DLLVM_ENABLE_LIBCXX=ON \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON \
        -DLIBCXX_ENABLE_STATIC=ON \
        -DLIBCXX_USE_COMPILER_RT=ON \
        -DLIBCXXABI_ENABLE_STATIC=ON \
        -DLIBCXXABI_USE_COMPILER_RT=ON \
        -DLLVM_RAM_PER_LINK_JOB=10000 \
        -DLLVM_INSTALL_UTILS=ON \
        -DLLVM_ENABLE_PIC=ON \
        -DLLVM_CCACHE_BUILD=ON \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_ENABLE_DUMP=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        -DLIBUNWIND_USE_COMPILER_RT=ON \
        -DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON \
        -DCOMPILER_RT_USE_LLVM_UNWINDER=ON \
        -DLLVM_POLLY_LINK_INTO_TOOLS=ON \
        -DLLVM_ENABLE_PROJECTS="bolt;clang;clang-tools-extra;cross-project-tests;libclc;lld;lldb;mlir;polly" \
        -DLLVM_ENABLE_RUNTIMES="libc;compiler-rt;libunwind;libcxxabi;pstl;libcxx;openmp;llvm-libgcc" \
        -S"${LLVM_SOURCE_DIR}/llvm" \
        -B"${LLVM_PROD_BUILD_DIR}" \
        --fresh
fi

WANT_TO_BUILD_LLVM=$(get_cache_or_default "WANT_TO_BUILD_LLVM" "y")
WANT_TO_BUILD_LLVM="$(u_prompt "Compile LLVM? [y/N] (default: $WANT_TO_BUILD_LLVM) " "$WANT_TO_BUILD_LLVM" -n 1)"
echo
set_cache "WANT_TO_BUILD_LLVM" "$WANT_TO_BUILD_LLVM"
if [[ $WANT_TO_BUILD_LLVM =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Compile LLVM in $LLVM_PROD_BUILD_DIR"
    cmake --build "${LLVM_PROD_BUILD_DIR}" --parallel "$HALF_CPUS"
fi

WANT_TO_INSTALL_LLVM=$(get_cache_or_default "WANT_TO_INSTALL_LLVM" "y")
WANT_TO_INSTALL_LLVM="$(u_prompt "Install LLVM? [y/N] (default: $WANT_TO_INSTALL_LLVM) " "$WANT_TO_INSTALL_LLVM" -n 1)"
echo
set_cache "WANT_TO_INSTALL_LLVM" "$WANT_TO_INSTALL_LLVM"
if [[ $WANT_TO_INSTALL_LLVM =~ ^[Yy]$ ]]; then
    dots_message "$CYAN" 6 "Install LLVM"
    cmake --install "${LLVM_PROD_BUILD_DIR}"
fi
