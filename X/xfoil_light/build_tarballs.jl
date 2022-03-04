using BinaryBuilder, Pkg

name = "xfoil_light"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/byuflowlab/xfoil_light.git", "7e1ac9cea9de6941b293a66b47198e7ab4ec4e7f")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd xfoil_light/
install_license LICENSE
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libxfoil_light", :libxfoil_light),
    LibraryProduct("libxfoil_light_cs", :libxfoil_light_cs)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
