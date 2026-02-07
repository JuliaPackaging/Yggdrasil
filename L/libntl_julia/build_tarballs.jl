# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

name = "libntl_julia"
version = v"0.2.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/s-celles/libntl-julia-wrapper.git",
              "2d7ccbe0572840c476273509b7b52bd6d18ca2d5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libntl-julia-wrapper

mkdir -p build && cd build

cmake .. \
    -DJulia_PREFIX=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=${prefix}

cmake --build . --parallel ${nproc}
cmake --install .

install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line. We need CxxWrap support.
# Filter out Julia DEV versions (1.13, 1.14) - not yet supported by libcxxwrap_julia_jll
filter!(v -> v < v"1.13", julia_versions)
platforms = vcat(libjulia_platforms.(julia_versions)...)

# Filter to platforms supported by ntl_jll (only Linux x86_64, i686, x86_64-musl)
ntl_platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("x86_64", "linux"; libc="musl"),
]
filter!(p -> any(q -> arch(p) == arch(q) && os(p) == os(q) && libc(p) == libc(q), ntl_platforms), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libntl_julia", :libntl_julia),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="0.14"),
    Dependency("ntl_jll"),
    Dependency("GMP_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10",
    julia_compat="1.6")
