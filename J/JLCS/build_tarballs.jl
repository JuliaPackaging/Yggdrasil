# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "JLCS"
version = v"3.0.0"

# libJLCS is the JLCS MLIR dialect of RepliBuild.jl: the library that lowers
# and JITs the call thunks RepliBuild's Julia wrappers of C++ and Rust
# libraries go through. Its sources are RepliBuild.jl's `src/mlir`, versioned
# and tagged apart from the Julia package.
sources = [
    GitSource("https://github.com/obsidianjulua/RepliBuild.jl.git",
              "dcf6a2ee4b29c143777d651045165ad614bd1802"; tag="jlcs-v$(version)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/RepliBuild.jl/src/mlir

# JLCS_STATIC_LLVM links LLVM's and MLIR's archives in and exports only the
# library's C API, so it loads beside Julia's own libLLVM, of another version,
# sharing no symbol with it.
# MLIR's CMake package names its own mlir-tblgen as the generator, and that is
# a target binary; JLCS_MLIR_TABLEGEN names the host's, which runs here.
cmake -S . -B ${WORKSPACE}/jlcs-build -GNinja \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_DIR=${prefix}/lib/cmake/llvm \
    -DMLIR_DIR=${prefix}/lib/cmake/mlir \
    -DJLCS_MLIR_TABLEGEN=${host_prefix}/tools/mlir-tblgen \
    -DJLCS_STATIC_LLVM=ON
cmake --build ${WORKSPACE}/jlcs-build -j${nproc}
cmake --install ${WORKSPACE}/jlcs-build

install_license ${WORKSPACE}/srcdir/RepliBuild.jl/LICENSE
"""

platforms = supported_platforms()
# The dialect lowers a call the way the host's C calling convention passes it,
# and has those rules for x86-64 and AArch64 only: its sources `#error` on any
# other architecture.
filter!(p -> arch(p) in ("x86_64", "aarch64"), platforms)
# The export list is a GNU version script, and the build refuses
# JLCS_STATIC_LLVM where the object format is not ELF.
filter!(p -> !Sys.iswindows(p) && !Sys.isapple(p), platforms)
# The library is linked with `-z defs`, and FreeBSD's libc leaves `environ`,
# which LLVMSupport refers to, to the executable: `ld.lld: error: undefined
# symbol: environ`.
filter!(!Sys.isfreebsd, platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libJLCS", :libJLCS),
]

# One build for every Julia: the LLVM it is built from is linked in, so it is
# a build dependency only and the library is not tied to Julia's LLVM version.
llvm_version = v"23.1.4+1"

dependencies = [
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
    # libgcc_s
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
    # LLVM_full's archives are built with zlib and zstd enabled, so the
    # library loads libz and libzstd.
    Dependency("Zlib_jll"; compat="1.2.12"),
    Dependency("Zstd_jll"; compat="1.5.7"),
]

# GCC 10 is what LLVM_full_jll 23 is built with, and its archives are linked in.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"10")
