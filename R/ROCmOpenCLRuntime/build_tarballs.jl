# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROCmOpenCLRuntime"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCm-Developer-Tools/ROCclr/archive/rocm-$(version).tar.gz",
                  "c57525af32c59becf56fd83cdd61f5320a95024d9baa7fb729a01e7a9fcdfd78"),
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/archive/rocm-$(version).tar.gz",
                  "18133451948a83055ca5ebfb5ba1bd536ed0bcb611df98829f1251a98a38f730"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
OPENCL_SRC=$(realpath $WORKSPACE/srcdir/ROCm-OpenCL-Runtime-*)
ROCCLR_SRC=$(realpath $WORKSPACE/srcdir/ROCclr-*)

cd $ROCCLR_SRC
atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-install-prefix.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-link-lrt.patch
if [[ "${target}" == *-musl* ]]; then
atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-disable-initial-exec.patch
fi
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DOPENCL_DIR=$OPENCL_SRC \
      -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
      -DClang_DIR="${prefix}/lib/cmake/clang" \
      -DLLD_DIR="${prefix}/lib/cmake/ldd" \
      ..
make -j${nproc}
make install

cd $OPENCL_SRC
if [[ "${target}" == *-musl* ]]; then
atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-opencl.patch
fi
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_COMGR_LIBRARY=ON \
      -DBUILD_TESTS:BOOL=OFF \
      -DBUILD_TESTING:BOOL=OFF \
      -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
      -DClang_DIR="${prefix}/lib/cmake/clang" \
      -DLLD_DIR="${prefix}/lib/cmake/ldd" \
      ..
make -j${nproc}
make install
install_license ../LICENSE.txt

# fix paths to point from src dir to install dir
sed -i "s#$ROCCLR_SRC/build#$WORKSPACE/destdir/lib#" $WORKSPACE/destdir/lib/cmake/rocclr/rocclr-targets.cmake
sed -i "s#$ROCCLR_SRC/include\;##" $WORKSPACE/destdir/lib/cmake/rocclr/rocclr-targets.cmake
sed -i "s#$ROCCLR_SRC#$WORKSPACE/destdir/include#g;s#$OPENCL_SRC.*\;##g" $WORKSPACE/destdir/lib/cmake/rocclr/rocclr-targets.cmake
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libamdocl64"], :libamdocl),
    LibraryProduct(["libOpenCL"], :libOpenCL),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hsa_rocr_jll", v"4.2.0"),
    Dependency("hsakmt_roct_jll", v"4.2.0"),
    Dependency("ROCmDeviceLibs_jll", v"4.2.0"),
    Dependency("ROCmCompilerSupport_jll", v"4.2.0"),
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version="4.2.0")),
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
