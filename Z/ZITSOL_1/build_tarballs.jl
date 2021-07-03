# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZITSOL_1"
version = v"0.1.1"

# Collection of sources required to complete build
sources = [GitSource("https://github.com/JuhaHeiskala/zitsol_mod.git",
                     "d9878e22218d1b050af876624af4ebdf163354dc")
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
# FreeBSD build failed with libgfortran_version=3.0.0
platforms = supported_platforms(; experimental=true)
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libZITSOL_1", :libZITSOL_1)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being need LLVM 11 because of <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158>.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_llvm_version=v"11")
