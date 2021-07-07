# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROCmCompilerSupport"
version = v"4.0.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-CompilerSupport/archive/rocm-$(version).tar.gz",
                  "f389601fb70b2d9a60d0e2798919af9ddf7b8376a2e460141507fe50073dfb31"), # 4.0.0
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
ln -s $WORKSPACE/destdir/tools/* $WORKSPACE/destdir/bin/

cd ${WORKSPACE}/srcdir/ROCm-CompilerSupport*/lib/comgr
atomic_patch -p1 $WORKSPACE/srcdir/patches/disable-1031.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/disable-tests.patch
mkdir build && cd build
export CC=clang
export CXX=clang++
# TODO: -DROCM_DIR=${prefix}
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      ..
make -j${nproc}
make install
ldd $WORKSPACE/destdir/lib64/libamd_comgr.so

find $WORKSPACE/destdir/bin -type l -delete
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libamd_comgr"], :libamd_comgr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("LLVM_full_jll", v"11.0.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
