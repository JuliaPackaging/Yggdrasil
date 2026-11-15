# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TVMFFI"
version = v"0.1.5"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/apache/tvm-ffi.git", "25c25aec22acadcf1aeb839297fe156bc0cf7183")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/tvm-ffi
git submodule update --init
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DTVM_FFI_ATTACH_DEBUG_SYMBOLS=ON \
    -DTVM_FFI_BUILD_TESTS=OFF \
    -DTVM_FFI_BUILD_PYTHON_MODULE=OFF \
    -DTVM_FFI_BACKTRACE_ON_SEGFAULT=OFF \
    -B ../../build
cmake --build ../../build
cmake --install ../../build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(exclude=Sys.iswindows)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libtvm_ffi", :libtvm_ffi),
    LibraryProduct("libtvm_ffi_testing", :libtvm_ffi_testing),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
