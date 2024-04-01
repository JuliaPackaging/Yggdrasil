# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MQLib"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MQLib/MQLib.git",
              "686a4fc52b9d2037b4a9ed55fbd178cc9e60ebc3"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/MQLib/
# https://github.com/MQLib/MQLib/pull/6
atomic_patch -p1 ../patches/cxx-makefile.patch
# https://github.com/MQLib/MQLib/pull/7
atomic_patch -p1 ../patches/math-defines.patch
# https://github.com/MQLib/MQLib/pull/8
atomic_patch -p1 ../patches/include-limits.patch
make -j${nproc}
install -Dvm 0755 bin/MQLib "${bindir}/MQLib${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    ExecutableProduct("MQLib", :MQLib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isapple, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
