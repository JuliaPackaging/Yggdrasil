# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PRIMA"
version = v"0.7.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libprima/prima.git", "af58422ee307f6401a560454c696f229ae8e9bdf")
]

# Bash recipe for building across all platforms
script = raw"""
cd prima
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build build --target install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
platforms = filter(p -> libgfortran_version(p) != v"3", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libprimac", :libprimac),
    LibraryProduct("libprimaf", :libprimaf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
