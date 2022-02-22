# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zimg"
version = v"3.0.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/sekrit-twc/zimg/archive/refs/tags/release-$(version).tar.gz", "5e002992bfe8b9d2867fdc9266dc84faca46f0bfd931acc2ae0124972b6170a7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zimg-release-*
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> arch(p) == "aarch64")
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libzimg", :libzimg)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
