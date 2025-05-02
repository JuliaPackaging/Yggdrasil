# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "N2QN1"
version = v"3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/fuentes/n2qn1.git", "7c74437b3439ea32e88df2f7e69e166a070e8568")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/n2qn1
cmake -B build -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build 
cmake --install build
install_license ${WORKSPACE}/srcdir/n2qn1/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libn2qn1", :libn2qn1)
]
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
