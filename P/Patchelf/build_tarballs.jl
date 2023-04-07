# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Patchelf"
version = v"0.17.2"

sources = [
    ArchiveSource("https://github.com/NixOS/patchelf/releases/download/$(version)/patchelf-$(version).tar.bz2",
                  "bae2ea376072e422c196218dd9bdef0548ccc08da4de9f36b4672df84ea2d8e2"),
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
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("patchelf", :patchelf),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
