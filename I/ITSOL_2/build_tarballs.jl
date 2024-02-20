# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ITSOL_2"
version = v"0.1.2"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/JuhaHeiskala/itsol_mod.git",
                  "36319fcb6d154d664e3c27c0eac04867962979e3")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/itsol_mod

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DJLL_BUILD=1 ..
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
    LibraryProduct("libITSOL_2", :libITSOL_2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll"); compat="5.4"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being need LLVM 11 because of <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158>.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_llvm_version=v"11")
