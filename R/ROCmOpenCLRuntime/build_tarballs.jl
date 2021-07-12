# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ROCmOpenCLRuntime"
version = v"4.0.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCm-Developer-Tools/ROCclr/archive/rocm-$(version).tar.gz",
                  "8db502d0f607834e3b882f939d33e8abe2f9b55ddafaf1b0c2cd29a0425ed76a"), # 4.0.0
    ArchiveSource("https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime/archive/rocm-$(version).tar.gz",
                  "d43ea5898c6b9e730b5efabe8367cc136a9260afeac5d0fe85b481d625dd7df1"), # 4.0.0
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
OPENCL_SRC=$(realpath $WORKSPACE/srcdir/ROCm-OpenCL-Runtime-*)
ROCCLR_SRC=$(realpath $WORKSPACE/srcdir/ROCclr-*)

cd $ROCCLR_SRC
atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-rocclr.patch
atomic_patch -p1 $WORKSPACE/srcdir/patches/rocclr-install-prefix.patch
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DOPENCL_DIR=$OPENCL_SRC \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
      -DLLVM_DIR="${prefix}/lib/cmake/llvm" \
      -DClang_DIR="${prefix}/lib/cmake/clang" \
      -DLLD_DIR="${prefix}/lib/cmake/ldd" \
      ..
make -j${nproc}
make install

cd $OPENCL_SRC
atomic_patch -p1 $WORKSPACE/srcdir/patches/musl-opencl.patch
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_COMGR_LIBRARY=ON \
      -DBUILD_TESTS:BOOL=OFF \
      -DBUILD_TESTING:BOOL=OFF \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
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
    LibraryProduct(["libamdocl64"], :libamdocl; dont_dlopen=true),
    LibraryProduct(["libOpenCL"], :libOpenCL; dont_dlopen=true),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("ROCmCompilerSupport_jll"),
    BuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"11.0.1")),
    Dependency("Libglvnd_jll"),
    Dependency("Xorg_libX11_jll"),
    Dependency("Xorg_xorgproto_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8", preferred_llvm_version=v"11")
