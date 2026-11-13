# Draft recipe for Yggdrasil (github.com/JuliaPackaging/Yggdrasil), to go to
# U/ulm_lam/build_tarballs.jl there.  It builds ulm_lam_jll: the ulm.lam
# compiler as one executable, linked statically against MLIR (Multi-Level
# Intermediate Representation) and LLVM (Low Level Virtual Machine), so
# that it does not depend on the libLLVM of the Julia it runs under.
#
# Local test (needs Docker, see BinaryBuilder.jl):
#   julia --project=@bb build_tarballs.jl --verbose --debug aarch64-apple-darwin
using BinaryBuilder, Pkg

name = "ulm_lam"
version = v"0.1.0"
llvm_version = v"23.1.4"

sources = [
    # UlmLAM 0.1.0
    GitSource("https://github.com/michael-lehn/ulm-lam.git",
              "9ad46d536758385e124fd4d3c8646ce0e91121f3"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ulm-lam

# mlir-tblgen runs on the build machine: the host's LLVM_full_jll's
TBLGEN=${host_prefix}/bin/mlir-tblgen
[ -x "${TBLGEN}" ] || TBLGEN=${host_prefix}/tools/mlir-tblgen

cmake -B build -S . -GNinja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CROSSCOMPILING=ON \
    -DLLVM_DIR=${prefix}/lib/cmake/llvm \
    -DMLIR_DIR=${prefix}/lib/cmake/mlir \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DULM_LAM_STATIC_LLVM=ON \
    -DULM_LAM_TABLEGEN=${TBLGEN}
ninja -C build -j${nproc}
ninja -C build install
install_license LICENSE
"""

# LLVM_full_jll is built for these; 32-bit is not worth it for a compiler
# whose output calls BLAS (Basic Linear Algebra Subprograms) on large matrices
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("ulm-lam", :ulm_lam),
    FileProduct("include/ulm_lam/cblas_backend.h", :cblas_backend_h),
]

dependencies = [
    # headers, static libraries and CMake files of LLVM and MLIR (only at
    # build time: everything is linked statically)
    # (the version as a string, as in P/pocl: a VersionNumber does not
    # match the registered 23.1.4+1)
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    # mlir-tblgen for the build machine
    HostBuildDependency(PackageSpec(name="LLVM_full_jll", version=string(llvm_version))),
    # LLVMSupport compresses with zlib and zstd
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# GCC 10: the C++ standard library LLVM_full_jll 23 was built with
build_tarballs(ARGS, name, version, sources, script, platforms, products,
               dependencies; julia_compat="1.10", preferred_gcc_version=v"10")
