# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SEAL"
version = v"3.6.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/microsoft/SEAL/archive/v$(version).tar.gz",
                  "1e2a97deb1f5b543640fc37d7b4737cab2a9849f616c13ff40ad3be4cf29fb9c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SEAL-*

# The last '-DSEAL_USE__*' and `-DSEAL*_EXITCODE*` flags are required to circumvent
# cross-compilation issues
if [[ "${target}" == *-darwin* ]]; then
  # C++17 is disabled on MacOS due to the environment being too old.
  cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE=1 \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE=1 \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__SUBBORROW_U64=OFF \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE=1 \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_MEMSET_S_FOUND_EXITCODE=1 \
    -DSEAL_MEMSET_S_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE_CXX17=OFF
elif [[ "${target}" == *-freebsd* ]]; then
  cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE=1 \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE=1 \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__SUBBORROW_U64=OFF \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE=1 \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_MEMSET_S_FOUND_EXITCODE=1 \
    -DSEAL_MEMSET_S_FOUND_EXITCODE__TRYRUN_OUTPUT=1
elif [[ "${target}" == aarch64* ]]; then
  cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE=1 \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE=1 \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__SUBBORROW_U64=OFF \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE=1 \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_ARM64_EXITCODE=1 \
    -DSEAL_ARM64_EXITCODE__TRYRUN_OUTPUT=1
else
  cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSEAL_BUILD_SEAL_C=ON \
    -DSEAL_USE___BUILTIN_CLZLL=OFF \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE=1 \
    -DSEAL___BUILTIN_CLZLL_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__ADDCARRY_U64=OFF \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE=1 \
    -DSEAL__ADDCARRY_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1 \
    -DSEAL_USE__SUBBORROW_U64=OFF \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE=1 \
    -DSEAL__SUBBORROW_U64_FOUND_EXITCODE__TRYRUN_OUTPUT=1
fi
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64; libc=:glibc),
    Linux(:x86_64; libc=:musl),
    Linux(:aarch64; libc=:glibc),
    Linux(:aarch64; libc=:musl),
    Linux(:powerpc64le; libc=:glibc),
    MacOS(:x86_64),
    FreeBSD(:x86_64)
]

# Fix incompatibilities across the GCC 4/5 version boundary due to std::string,
# as suggested by the wizard
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsealc", :libsealc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"7.1.0")
