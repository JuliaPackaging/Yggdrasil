# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "squashfs_tools"
version = v"4.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/plougher/squashfs-tools.git", "d8cb82d9840330f9344ec37b992595b5d7b44184"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/squashfs-tools/squashfs-tools/

# `XATTR_OS_SUPPORT=0` seems to have a bug
atomic_patch -p1 ../../patches/xattr_os_support.patch

if [[ $target == *-freebsd* ]] || [[ $target == *-mingw* ]]; then
    # Disable OS xattr support on FreeBSD and Windows
    XATTR_OS_SUPPORT=0
else
    XATTR_OS_SUPPORT=1
fi

env CONFIG=1 make XZ_SUPPORT=1 LZO_SUPPORT=1 LZ4_SUPPORT=1 ZSTD_SUPPORT=1 XATTR_OS_SUPPORT=${XATTR_OS_SUPPORT} -j${nproc}
cp mksquashfs unsquashfs ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    ExecutableProduct("unsquashfs", :unsquashfs),
    ExecutableProduct("mksquashfs", :mksquashfs),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency.(["Zlib_jll", "XZ_jll", "LZO_jll", "Lz4_jll", "Zstd_jll"])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
