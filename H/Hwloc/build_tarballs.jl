# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Hwloc"
version = v"2.9.1"

# Collection of sources required to build hwloc
sources = [
    ArchiveSource("https://download.open-mpi.org/release/hwloc/v$(version.major).$(version.minor)/hwloc-$(version).tar.bz2",
                  "7cc4931a20fef457e0933af3f375be6eafa7703fde21e137bfb9685b1409599e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/hwloc-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhwloc", :libhwloc),
    ExecutableProduct("lstopo-no-graphics", :lstopo_no_graphics)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
