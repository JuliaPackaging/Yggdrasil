#!/bin/bash
set -e

# This bash file acts as, essentially, a build system to run through a full
# rootfs and compiler shard compilation run.  Note that it very eagerly accepts
# previously built tarballs and squashfs files, and therefore will not rebuild
# tarballs it doesn't think it needs to.

# We're essentially going to ship three things:
# * KernelHeaders + Libc + Binutils (per-target)
# * GCC (per-target and per-ABI)
# * LLVM (single product for everybody)
#
# Everything else is either a host tool contained within the base
# rootfs image, or not shipped.  We ship these files as tarballs
# and .squashfs files.  So we build each project individually, then
# assemble the first bullet point into "base compiler shards", then
# create .squashfs versions of the output of all three groupings above.


# All the machines
MACHINES=$(julia -e 'using BinaryBuilder; println(join(triplet.(supported_platforms()), " "))')
GLIBC_VERSIONS="2.17 2.19 2.25"
GLIBC_MACHINES_217="x86_64-linux-gnu i686-linux-gnu"
GLIBC_MACHINES_219="arm-linux-gnueabihf aarch64-linux-gnu"
GLIBC_MACHINES_225="x86_64-linux-gnu i686-linux-gnu powerpc64le-linux-gnu"
MUSL_MACHINES="x86_64-linux-musl i686-linux-musl arm-linux-musleabihf aarch64-linux-musl"
MINGW_MACHINES="x86_64-w64-mingw32 i686-w64-mingw32"
FREEBSD_MACHINES="x86_64-unknown-freebsd11.1"
MACOS_MACHINES="x86_64-apple-darwin14"
GCC_VERSIONS="4.8.5 7.1.0 8.1.0" #4.9.4 6.1.0"

BUILD_ARGS=()
for arg in "$@"; do
    case $arg in
        --verbose)
            BUILD_ARGS+=("--verbose")
            ;;
        --debug)
            BUILD_ARGS+=("--debug")
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
        echo "Skipping $(basename "${SQUASHFS_PATH}")"
        return
    fi
    echo "  -> Compressing into $(basename ${SQUASHFS_PATH})"

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
    if [[ -f "$(echo products/*${2}*.tar.gz)" ]]; then
        echo "  -> Skipping ${2}"
        return
    fi
    echo "  -> Building ${1} ${3}"
    julia --color=yes build_tarballs.jl ${BUILD_ARGS[@]} ${3}
    )
    make_squashfs "$(echo ${1}/products/*${2}*.tar.gz)"
}

build_host()
{
    echo "Building ${1}..."
    build_cached ${1} "${1}*.x86_64-linux-gnu" x86_64-linux-gnu
}

build_all_machines()
{
    echo "Building ${1}..."
    for m in ${MACHINES}; do
        build_cached ${1} "${1}*.${m}" ${m}
    done
}

# Start with building host-only tools and rootfs
build_host Objconv
build_host Patchelf
build_host Sandbox
build_host Linux
for v in ${GLIBC_VERSIONS}; do
    NODOT_VERSION=$(echo ${v} | tr -d '.')
    GLIBC_MACHINES_VAR="GLIBC_MACHINES_${NODOT_VERSION}"
    for m in ${!GLIBC_MACHINES_VAR}; do
        build_cached Glibc "Glibc*${v}*${m}" "--glibc-version ${v} ${m}"
    done
done
build_host Rootfs

# Next build kernel headers
build_all_machines KernelHeaders

# Then build binutils
echo "Building Binutils..."
for m in ${MACHINES}; do
    build_cached Binutils "Binutils-${m}*.x86_64-linux-gnu" ${m}
done


# Next, Musl, Mingw, FreeBSD and MacOS
echo "Building C runtimes..."
for m in ${MUSL_MACHINES}; do
    build_cached Musl "Musl*${m}" ${m}
done
for m in ${MINGW_MACHINES}; do
    build_cached Mingw "Mingw*${m}" ${m}
done
for m in ${FREEBSD_MACHINES}; do
    build_cached FreeBSDLibc "FreeBSDLibc*${m}" ${m}
done
for m in ${MACOS_MACHINES}; do
    build_cached MacOSLibc "MacOSLibc*${m}" ${m}
done

# Assemble base compiler shards
for m in ${MACHINES}; do
    build_cached BaseCompilerShard "BaseCompilerShard-${m}" ${m}
done

# Next build GCC
echo "Building GCC..."
for v in ${GCC_VERSIONS}; do
    for m in ${MACHINES}; do
        build_cached GCC "GCC-${m}*${v}*x86_64-linux-gnu" "--gcc-version ${v} ${m}"
    done
done

# Next build LLVM, and we're done!
build_host LLVM


## As an aside, I have realized that somehow, my Julia projects always wind
## up with me rewriting some kind of build system in bash.  I need to make
## a covenant with myself to move away from these kinds of projects and do
## something more interesting, like mashing the refresh button on the Julia
## homepage to drive our traffic stats up, or grinding rocks to sand.
