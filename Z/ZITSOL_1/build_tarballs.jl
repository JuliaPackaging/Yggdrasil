# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZITSOL_1"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/JuhaHeiskala/zitsol_mod.git",
                     "9e4c7d5ab9c65f1e96db698d5005cd2011dcd492")
]

# Bash recipe for building across all platforms
# generate CMakeLists.txt on the fly.
script = raw"""
cd $WORKSPACE/srcdir/zitsol_mod

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DJLL_BUILD=1 ..
make -j${nproc}
make install

install_license ../{COPYRIGHT,LGPL}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libZITSOL_1", :libZITSOL_1)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll"); compat="5.4"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being need LLVM 11 because of <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158>.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_llvm_version=v"11")
