# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "cminpack"
version = v"1.3.11"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/devernay/cminpack.git", "17dab75c6160d2ee42a3c95ea55e94738d7e559d"),
]

# Bash recipe for building across all platforms
script = raw"""

# We need a newer version of CMake to support libblastrampoline
apk del cmake

cd $WORKSPACE/srcdir/cminpack

options=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DBUILD_SHARED_LIBS=ON
    -DBUILD_EXAMPLES=OFF
    -DBLA_VENDOR=libblastrampoline
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

# The products that we will ensure are always built
products = [
    LibraryProduct("libcminpack", :libcminpack),
    LibraryProduct("libcminpacks", :libcminpacks),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"; compat="5.4"),
    # We need at least 3.29 (Ygg version), or 3.30 upstream version
    # for LBT support, so always pull the most recent CMake version.
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9")
