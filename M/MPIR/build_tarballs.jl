# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPIR"
version = v"3.0.0"

# Collection of sources required to build MPFRBuilder
sources = [
    ArchiveSource("https://mpir.org/mpir-$(version).tar.bz2",
                  "52f63459cf3f9478859de29e00357f004050ead70b45913f2c2269d9708675bb"),
]

version = v"3.0.1" # Fake version bump for compat

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpir-*

./configure --enable-cxx --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static --enable-shared
make -j
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> arch(p) != "x86_64" || Sys.isfreebsd(p))
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpir", :libmpir)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("YASM_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
