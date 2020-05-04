# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NL2sol"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/macd/NL2sol.f.git", "4bdb74e725cb9996095f7b46b9e99ff7fe8f3f8e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/NL2sol.f
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
cd ..
mkdir -p ${libdir}
mv -f libnl2sol.${dlext} ${libdir}
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libnl2sol", :libnl2sol)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
