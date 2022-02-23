# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROCmCompilerSupport"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-CompilerSupport/archive/rocm-$(version).tar.gz",
                  "40a1ea50d2aea0cf75c4d17cdd6a7fe44ae999bf0147d24a756ca4675ce24e36"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
ln -s ${bindir}/../tools/* ${bindir}/

cd ${WORKSPACE}/srcdir/ROCm-CompilerSupport*/lib/comgr

# first manually build bc2h utility
cd cmake && mkdir bc2h && cd bc2h
cp ../bc2h.cmake CMakeLists.txt
CC=$HOSTCC cmake -DCMAKE_C_COMPILER=$HOSTCC .
make
cd ../..

# then build everything else
atomic_patch -p1 $WORKSPACE/srcdir/patches/disable-bc2h.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/fix-objdump-clopt.patch
mkdir build && cd build
cp ../cmake/bc2h/bc2h .
# TODO: -DROCM_DIR=${prefix}
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
      -DClang_DIR="${prefix}/lib/cmake/clang" \
      -DLLD_DIR="${prefix}/lib/cmake/ldd" \
      -DBUILD_TESTING:BOOL=OFF \
      ..
PATH=../cmake/bc2h:$PATH make -j${nproc}
make install

find $WORKSPACE/destdir/bin -type l -delete
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # TODO: cxx03
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libamd_comgr"], :libamd_comgr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
