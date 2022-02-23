# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Patchelf"
version = v"0.14.3"

sources = [
    ArchiveSource("https://github.com/NixOS/patchelf/releases/download/$(version)/patchelf-$(version).tar.bz2",
                  "a017ec3d2152a19fd969c0d87b3f8b43e32a66e4ffabdc8767a56062b9aec270"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
