# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Libbpf"
version = v"0.3"

# Collection of sources required to build libbpf
sources = [
    ArchiveSource("https://github.com/libbpf/libbpf/archive/v$(version.major).$(version.minor).tar.gz",
                  "c168d84a75b541f753ceb49015d9eb886e3fb5cca87cdd9aabce7e10ad3a1efc"),
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
platforms = [p for p in supported_platforms() if Sys.islinux(p)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libbpf", :libbpf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Elfutils_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
