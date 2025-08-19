# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "squashfs_tools"
version = v"4.7.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/plougher/squashfs-tools.git", "99d23a31b471433c51e9c145aeba2ab1536e34df"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/squashfs-tools/squashfs-tools

# Reported as <https://github.com/plougher/squashfs-tools/issues/324>
atomic_patch -p1 $WORKSPACE/srcdir/patches/nprocessors_compat.patch

args=(XZ_SUPPORT=1 LZO_SUPPORT=1 LZ4_SUPPORT=1 ZSTD_SUPPORT=1)
if [[ "${target}" == *-mingw* ]] || [[ "${target}" == *-freebsd* ]]; then
    args+=(XATTR_OS_SUPPORT=0)
fi

env CONFIG=1 make -j${nproc} ${args[@]}
cp mksquashfs unsquashfs ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# The Windows build fails
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("unsquashfs", :unsquashfs),
    ExecutableProduct("mksquashfs", :mksquashfs),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency.(["Zlib_jll", "XZ_jll", "LZO_jll", "Lz4_jll", "Zstd_jll"])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
