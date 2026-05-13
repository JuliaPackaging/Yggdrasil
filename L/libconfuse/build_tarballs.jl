# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libconfuse"
upstream_version = v"3.3"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/martinh/libconfuse/releases/download/v$(upstream_version)/confuse-$(upstream_version).tar.gz",
                  "3a59ded20bc652eaa8e6261ab46f7e483bc13dad79263c15af42ecbb329707b8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/confuse-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libconfuse", :libconfuse)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
