#!/bin/sh

# shellcheck source=/dev/null
. /etc/release

if [ -z "${ID}" ]; then
    echo "ID is not set"
    exit 1
fi

distro=""
case ${ID} in
ubuntu | debian)
    distro="debian"
    ;;
*)
    distro="${ID}"
    ;;
esac

"./scripts/${distro}/build.sh"