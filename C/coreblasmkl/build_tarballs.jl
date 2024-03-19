# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "coreblasmkl"
version = v"23.8.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Rabab53/CoreBlas.git", "cf603a85fcbb089d0558e59766458858827e71a0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd CoreBlas/
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release 
cmake --build build --parallel ${nproc}
cmake --install build
logout
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcoreblas_blas", :coreblasmkl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MKL_jll", uuid="856f044c-d86e-5d09-b602-aeab76dc8ba7"))
    Dependency(PackageSpec(name="MKL_Headers_jll", uuid="b2f2f022-7a59-54f4-945e-e9b78c3fd545"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
