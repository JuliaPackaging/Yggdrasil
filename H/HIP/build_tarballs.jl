# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HIP"
version = v"4.0.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCm-Developer-Tools/HIP/archive/rocm-$(version).tar.gz",
                  #"e21c10b62868ece7aa3c8413ec0921245612d16d86d81fe61797bf9a64bc37eb"), # 4.1.0
                  "d7b78d96cec67c55b74ea3811ce861b16d300410bc687d0629e82392e8d7c857"), # 4.0.0
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/HIP*/

# disable broken Pre-Compiled Headers (PCH)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-pch.patch"

# help hipcc to find BB C++ headers+libs+crt
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/hipcc-bb-paths.patch"

# use rocclr instead of hcc as HIP_PLATFORM
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/rocclr-not-hcc-platform.patch"
#sed -e "s:\$HIP_PLATFORM eq \"hcc\" and \$HIP_COMPILER eq \"clang\":\$HIP_PLATFORM eq \"rocclr\" and \$HIP_COMPILER eq \"clang\":" -i bin/hipcc

apk add coreutils dateutils

mkdir build && cd build
export HIP_CLANG_PATH=${prefix}/tools
cmake -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
      -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DHIP_COMPILER=clang \
      -DHIP_PLATFORM=rocclr \
      -DHIP_RUNTIME=ROCclr \
      -DROCM_PATH=${prefix} \
      -DHSA_PATH=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_clang.cmake \
      -DLLVM_DIR="${libdir}/cmake/llvm" \
      -DClang_DIR="${libdir}/cmake/clang" \
      -DLLD_DIR="${libdir}/cmake/ldd" \
      ..
make -j${nproc}
make install

# link to .hipVersion so clang can find it
ln -s ../hip/bin/.hipVersion ${bindir}/.hipVersion
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi="cxx11"),
    Platform("x86_64", "linux"; libc="musl", cxxstring_abi="cxx11"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libamdhip64"], :libamdhip64, ["hip/lib"]),
    ExecutableProduct("hipcc", :hipcc, "hip/bin"),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="LLVM_full_jll", version=v"11.0.1")),
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("ROCmCompilerSupport_jll"),
    Dependency("ROCmOpenCLRuntime_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"8")
