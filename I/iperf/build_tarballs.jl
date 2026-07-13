# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "iperf"
version = v"3.21"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/esnet/iperf/releases/download/$(version.major).$(version.minor)/iperf-$(version.major).$(version.minor).tar.gz", "656e4405ebd620121de7ceca3eaf43a88f79ea1b857d041a6a0b1314801acdd8"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/iperf-*
atomic_patch -p1 $WORKSPACE/srcdir/patches/0001-use-uint64_t-for-atomic-fallback.patch # work around https://github.com/esnet/iperf/issues/2060
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-profiling
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libiperf", :libiperf),
    ExecutableProduct("iperf3", :iperf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
