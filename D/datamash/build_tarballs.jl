# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "datamash"
version = v"1.7.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/datamash/datamash-1.7.tar.gz", "574a592bb90c5ae702ffaed1b59498d5e3e7466a8abf8530c5f2f3f11fa4adb3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/datamash-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> !(p isa Windows), supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("datamash", :datamash)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
