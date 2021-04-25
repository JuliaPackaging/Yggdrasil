# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libudfread"
version = v"1.1.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://code.videolan.org/videolan/libudfread/-/archive/1.1.2/libudfread-1.1.2.tar.gz", "2bf16726ac98d093156195bb049a663e07d3323e079c26912546f4e05c77bac5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libudfread-*
./bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libudfread", :libudfread)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
