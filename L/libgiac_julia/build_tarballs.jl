# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms

name = "libgiac_julia"
version = v"0.4.0"

# Collection of sources required to build libgiac_julia
sources = [
    GitSource(
        "https://github.com/s-celles/libgiac-julia-wrapper.git",
        "4773340b0e45c420e9b6361b17b8aac165c658e4"
    ),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libgiac-julia-wrapper

# Help CMake find GIAC
export GIAC_ROOT="${prefix}"

# On Windows, ${libdir} points to bin/; import libraries (.dll.a) are in ${prefix}/lib/
GIAC_LIB="${libdir}/libgiac.${dlext}"
GMP_LIB="${libdir}/libgmp.${dlext}"
if [[ "${target}" == *mingw* ]]; then
    GIAC_LIB="${prefix}/lib/libgiac.dll.a"
    GMP_LIB="${prefix}/lib/libgmp.dll.a"
fi

# Extra CMake args for C-ABI mode (macOS/FreeBSD only)
CABI_CMAKE_ARGS=""

if [[ "${target}" == *-apple-* ]] || [[ "${target}" == *freebsd* ]]; then
    # On macOS/FreeBSD, GIAC_jll is built with g++/libstdc++ while
    # libcxxwrap_julia_jll uses clang++/libc++. The std::string types are
    # ABI-incompatible. We use a dual-compiler approach:
    #   1. Compile giac_impl.cpp + giac_cabi.cpp with g++ -> libgiac_cabi.a
    #   2. Compile giac_wrapper.cpp with clang++ (default) + USE_GIAC_CABI
    # The C-ABI shim bridges the two with extern "C" functions.

    echo "=== Building C-ABI shim with g++ ==="

    # Find g++ cross-compiler (BinaryBuilder provides it as ${target}-g++)
    GCC_CXX="${target}-g++"

    # Compile giac_impl.cpp (C++14, includes GIAC headers)
    ${GCC_CXX} -c -std=c++14 -O2 -fPIC \
        -I${includedir}/giac \
        -I${includedir}/giac/giac \
        -I${prefix}/include \
        src/giac_impl.cpp \
        -o /tmp/giac_impl.o

    # Compile giac_cabi.cpp (C++14, extern "C" bridge)
    ${GCC_CXX} -c -std=c++14 -O2 -fPIC \
        -I${includedir}/giac \
        -I${includedir}/giac/giac \
        -I${prefix}/include \
        -Isrc \
        src/giac_cabi.cpp \
        -o /tmp/giac_cabi.o

    # Create static library
    ar rcs /tmp/libgiac_cabi.a /tmp/giac_impl.o /tmp/giac_cabi.o

    echo "=== C-ABI shim built: /tmp/libgiac_cabi.a ==="

    # Find full paths to GCC runtime libraries (clang++ linker can't find them by default)
    LIBSTDCXX=$(${GCC_CXX} -print-file-name=libstdc++.a)
    LIBGCC=$(${GCC_CXX} -print-file-name=libgcc.a)
    LIBGCC_EH=$(${GCC_CXX} -print-file-name=libgcc_eh.a)
    echo "=== GCC runtime libs: ${LIBSTDCXX} ; ${LIBGCC} ; ${LIBGCC_EH} ==="

    CABI_CMAKE_ARGS="-DUSE_GIAC_CABI=ON -DGIAC_CABI_LIBRARY=/tmp/libgiac_cabi.a"
    CABI_CMAKE_ARGS="${CABI_CMAKE_ARGS} -DGCC_RUNTIME_LIBS=${LIBSTDCXX};${LIBGCC};${LIBGCC_EH}"
fi

# Build with CMake
cmake -B build \
   -DJulia_PREFIX="${prefix}" \
   -DGIAC_INCLUDE_DIR="${includedir}/giac" \
   -DGIAC_LIBRARY="${GIAC_LIB}" \
   -DGMP_LIBRARY="${GMP_LIB}" \
   -DCMAKE_INSTALL_PREFIX="${prefix}" \
   -DCMAKE_FIND_ROOT_PATH="${prefix}" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release \
   ${CABI_CMAKE_ARGS}

cmake --build build --config Release --target giac_wrapper -- -j${nproc}
cmake --install build

install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
include("../../L/libjulia/common.jl")
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# All platforms supported: macOS/FreeBSD use C-ABI shim to bridge
# g++ (GIAC_jll) and clang++ (libcxxwrap_julia_jll) ABI mismatch

# The products that we will ensure are always built
products = [
    LibraryProduct("libgiac_wrapper", :libgiac_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(;name="libjulia_jll", version="1.11.0")),
    BuildDependency("GMP_jll"),
    BuildDependency("MPFR_jll"),
    Dependency("libcxxwrap_julia_jll"; compat = "~0.14.9"),
    Dependency("GIAC_jll"; compat = "~2.0.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"10", julia_compat=libjulia_julia_compat(julia_versions))
