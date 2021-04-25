# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "zimg"
version = v"3.0.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/sekrit-twc/zimg/archive/refs/tags/release-3.0.1.tar.gz", "c50a0922f4adac4efad77427d13520ed89b8366eef0ef2fa379572951afcc73f")
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
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libzimg", :libzimg)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
