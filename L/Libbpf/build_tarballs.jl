# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libbpf"
version = v"0.5"

# Collection of sources required to build libbpf
sources = [
    ArchiveSource("https://github.com/libbpf/libbpf/archive/v$version.tar.gz",
                  "d5b27980ceab9a80b6f28d3e67b51cea526fda49bd13151ba966e33548feb4f4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libbpf-*/src/
for patchfile in $WORKSPACE/srcdir/patches/*; do
    atomic_patch -p1 $patchfile
done
make -j${nproc}
make install PREFIX=$prefix
cp -R ../include/uapi "$prefix/include/uapi"
"""

# Only build for Linux
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libbpf", :libbpf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Elfutils_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
