# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "HIP"
version = v"4.2.0"

# Collection of sources required to build
sources = [
    ArchiveSource("https://github.com/ROCm-Developer-Tools/HIP/archive/rocm-$(version).tar.gz",
                  "ecb929e0fc2eaaf7bbd16a1446a876a15baf72419c723734f456ee62e70b4c24"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/HIP*/

# disable broken Pre-Compiled Headers (PCH)
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-pch.patch"

# force hipcc to pass paths to clang
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/hipcc-force-paths.patch"

# help hipcc to find BB C++ headers+libs+crt
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/hipcc-bb-paths.patch"

# disable tests
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/disable-tests.patch"

# disable abort when failing to find code objects
atomic_patch -p1 --ignore-whitespace "${WORKSPACE}/srcdir/patches/no-init-abort.patch"

apk add coreutils dateutils

mkdir build && cd build
ln -s ${prefix}/bin/clang ${prefix}/tools/clang
export HIP_CLANG_PATH=${prefix}/tools
cmake -DCMAKE_INSTALL_PREFIX=${prefix}/hip \
      -DCMAKE_PREFIX_PATH=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DHIP_COMPILER=clang \
      -DHIP_PLATFORM=amd \
      -DHIP_RUNTIME=rocclr \
      -DROCM_PATH=${prefix} \
      -DHSA_PATH=${prefix} \
      -DLLVM_DIR="${libdir}/cmake/llvm" \
      -DClang_DIR="${libdir}/cmake/clang" \
      -DLLD_DIR="${libdir}/cmake/ldd" \
      ..
make -j${nproc}
make install

# Cleanup
rm ${prefix}/tools/clang

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
    BuildDependency(PackageSpec(; name="ROCmLLVM_jll", version=v"4.2.0")),
    Dependency("hsa_rocr_jll"),
    Dependency("ROCmDeviceLibs_jll"),
    Dependency("ROCmCompilerSupport_jll", v"4.2.0"),
    Dependency("ROCmOpenCLRuntime_jll", v"4.2.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.7",
               preferred_gcc_version=v"8")
