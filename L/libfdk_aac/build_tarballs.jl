# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libfdk_aac"
version = v"2.0.2"

# Collection of sources required to build libfdk
sources = [
    ArchiveSource("https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$(version).tar.gz",
                  "c9e8630cf9d433f3cead74906a1520d2223f89bcd3fa9254861017440b8eb22f"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fdk-aac-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-static
make -j${nproc}
make install
install_license NOTICE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libfdk-aac", :libfdk)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
