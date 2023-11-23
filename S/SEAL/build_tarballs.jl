# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SEAL"
version = v"4.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/SEAL.git", "206648d0e4634e5c61dcf9370676630268290b59")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SEAL

# Collect target-specific flags
# Note: The '-DSEAL_USE__*' and `-DSEAL*_EXITCODE*` flags are required to circumvent
# cross-compilation issues
TARGET_FLAGS=""
if [[ "${target}" == *-darwin* ]]; then
  # C++17 is disabled on MacOS due to the environment being too old.
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_MEMSET_S_FOUND_EXITCODE=1"
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_MEMSET_S_FOUND_EXITCODE__TRYRUN_OUTPUT=1"
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_USE_CXX17=OFF"
elif [[ "${target}" == *-freebsd* ]]; then
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_MEMSET_S_FOUND_EXITCODE=1"
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_MEMSET_S_FOUND_EXITCODE__TRYRUN_OUTPUT=1"
elif [[ "${target}" == aarch64* ]]; then
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_ARM64_EXITCODE=1"
  TARGET_FLAGS="$TARGET_FLAGS -DSEAL_ARM64_EXITCODE__TRYRUN_OUTPUT=1"
fi

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
  $TARGET_FLAGS

cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd")
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
               preferred_gcc_version = v"10.2.0")
