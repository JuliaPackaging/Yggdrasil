using BinaryBuilder, Pkg

name = "xfoil_light"
version = v"0.2.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/byuflowlab/xfoil_light.git", "03f182b13500ad1b5a88678d8e2ce4de7d155012")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xfoil_light/
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
