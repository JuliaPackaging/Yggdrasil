# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Patchelf"
version = v"0.13"

sources = [
    ArchiveSource("https://github.com/NixOS/patchelf/releases/download/$(version.major).$(version.minor)/patchelf-$(version.major).$(version.minor).tar.bz2",
                  "4c7ed4bcfc1a114d6286e4a0d3c1a90db147a4c3adda1814ee0eee0f9ee917ed"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/patchelf*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("patchelf", :patchelf),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
