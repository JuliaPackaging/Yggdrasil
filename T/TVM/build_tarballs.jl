# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TVM"
version = v"0.10.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dlcdn.apache.org/tvm/tvm-v$(version)/apache-tvm-src-v$(version).tar.gz", "2da001bf847636b32fc7a34f864abf01a46c69aaef0ff37cfbfbcc2eb5b0fce4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/apache-tvm-src-v0.10.0/
install_license LICENSE 
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$prefix \
         -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
         -DCMAKE_BUILD_TYPE=Release \
         -DUSE_LLVM=ON
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),

    # dll import woes
    # Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libtvm", :libtvm),
    LibraryProduct("libtvm_runtime", :libtvm_runtime),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="Zlib_jll")),
    Dependency(PackageSpec(name="XML2_jll")),
    Dependency(PackageSpec(name="LLVM_jll")),
    Dependency(PackageSpec(name="MLIR_jll")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8.1.0")
