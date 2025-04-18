# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cminpack"
version = v"1.3.11"
# We bumped the version number because we changed the dependencies
ygg_version = v"1.3.12"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/devernay/cminpack.git", "17dab75c6160d2ee42a3c95ea55e94738d7e559d"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cminpack

options=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_EXAMPLES=OFF
    -DBLA_VENDOR=OpenBLAS
    -DUSE_BLAS=ON
)

if [[ ${target} == *-apple-* ]]; then
    # cminpack calls Fortran functions without declaring them
    options+=(
        -DCMAKE_C_FLAGS=-Wno-error=implicit-function-declaration
    )
fi

# Build single precision library
cmake -B build_s -DCMINPACK_PRECISION="s" "${options[@]}"
cmake --build build_s --parallel ${nproc}
cmake --install build_s

# Build double precision library
cmake -B build_d -DCMINPACK_PRECISION="d" "${options[@]}"
cmake --build build_d --parallel ${nproc}
cmake --install build_d

install_license CopyrightMINPACK.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# OpenBLAS 0.3.29 doesn't support GCC < v11 on powerpc64le:
# <https://github.com/OpenMathLib/OpenBLAS/issues/5068#issuecomment-2585836284>.
# Also, we did not build OpenBLAS <0.3.29 for riscv64.
# To address this we need expand gfortran versions so that we can filter on them.
platforms = expand_gfortran_versions(platforms)
filter!(p -> !(arch(p) == "powerpc64le" && libgfortran_version(p) < v"5"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcminpack", :libcminpack),
    LibraryProduct("libcminpacks", :libcminpacks),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 5 for OpenBLAS32's `memcpy` calls on x86_64
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
