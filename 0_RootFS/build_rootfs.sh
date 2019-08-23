#!/bin/bash
set -e

# This bash file acts as, essentially, a build system to run through a full
# rootfs and compiler shard compilation run.  Note that it very eagerly accepts
# previously built tarballs and squashfs files, and therefore will not rebuild
# tarballs it doesn't think it needs to.

# We're going to ship five things:
# * RootFS (single product)
# * KernelHeaders + cmake toolchains + other misc. stuff (per-target)
# * Libc + Binutils + GCC (per-target and per-ABI)
# * LLVM (single product for everybody)
#
# Everything else is either a host tool contained within the base
# rootfs image, or not shipped.  We ship these files as tarballs
# and .squashfs files.  So we build each project individually, then
# assemble the first bullet point into "base compiler shards", then
# create .squashfs versions of the output of all three groupings above.


# All the machines
JULIA=${JULIA:-julia}
MACHINES=$(${JULIA} --color=yes -e 'using BinaryBuilder; println(join(triplet.(supported_platforms()), " "))')
GCC_VERSIONS="4.8.5 5.2.0 6.1.0 7.1.0 8.1.0"

BUILD_ARGS=()
for arg in "$@"; do
    case $arg in
        --verbose)
            BUILD_ARGS+=("--verbose")
            ;;
        --debug)
            BUILD_ARGS+=("--debug")
            ;;
        --clean)
            echo "Clearing builds..."
            ../clean_builds.sh
            ;;
        --nuke)
            echo "Clearing builds..."
            ../clean_builds.sh
            echo "Clearing products..."
            ../clean_products.sh
            ;;
        *)
            ;;
    esac
done

make_squashfs()
{
    TARBALL_PATH="$1"
    SQUASHFS_PATH="${1%.tar.gz}.squashfs"

    # Check to see if this file already exists and is newer than the tarball
    if [[ "${SQUASHFS_PATH}" -nt "${TARBALL_PATH}" ]]; then
        echo "  -> Skipping $(basename "${SQUASHFS_PATH}")"
        return
    fi
    echo "  -> Compressing into $(basename "${SQUASHFS_PATH}")"

    # Unpack to temporary directory
    WORK_DIR=$(mktemp -d)
    tar -C "${WORK_DIR}" -zxf "${TARBALL_PATH}"

    # Create .squashfs
    mksquashfs "${WORK_DIR}" "${SQUASHFS_PATH}" -force-uid 0 -force-gid 0 -comp xz -b 1048576 -Xdict-size 100% -noappend

    # Cleanup temporary directory
    rm -rf "${WORK_DIR}"
}


build_cached()
{
    (cd ${1}
    TARBALL="$(echo products/*${2}*.tar.gz)"
    if [[ -f "${TARBALL}" ]]; then
        echo "  -> Skipping $(basename "${TARBALL}")"
        return
    fi
    echo "  -> Building ${1} ${3}"
    ${JULIA} --color=yes build_tarballs.jl ${BUILD_ARGS[@]} ${3}
    )
    make_squashfs "$(echo ${1}/products/*${2}*.tar.gz)"
}

build_host()
{
    echo "Building ${1}..."
    build_cached ${1} "${1}.*.x86_64-linux-musl" x86_64-linux-musl
}

build_all_machines()
{
    echo "Building ${1}..."
    for m in ${MACHINES}; do
        build_cached ${1} "${1}*.${m}" ${m}
    done
}

## BOOTSTRAP ZONE ##
# Everything within here needs to set `BinaryBuilder.bootstrap = true`, which will cause
# BB to choose the latest installed rootfs as well as avoid mounting compiler shards.
# This is how we start out; small and light.

# Start by assembling the Rootfs
build_host Rootfs
./install_dev_rootfs.sh

# Collect Kernel Headers, cmake toolchains, etc... in anticipation of the GCC show about to come
build_all_machines PlatformSupport

# Let's get at it! 
for v in ${GCC_VERSIONS}; do
    for m in ${MACHINES}; do
        build_cached GCCBootstrap "GCCBootstrap-${m}*${v}*x86_64-linux-musl" "--gcc-version ${v} ${m}"
    done
done

# Next build LLVM, and we're done!
build_host LLVMBootstrap

# Deploy the rootfs we've got so far
./install_dev_rootfs.sh

# Build some useful tools as well
build_host Wine
build_host Qemu

## As an aside, I have realized that somehow, my Julia projects always wind
## up with me rewriting some kind of build system in bash.  I need to make
## a covenant with myself to move away from these kinds of projects and do
## something more interesting, like mashing the refresh button on the Julia
## homepage to drive our traffic stats up, or grinding rocks to sand.
