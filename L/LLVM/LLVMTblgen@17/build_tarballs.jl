# Tablegen tools for LLVM, Clang and MLIR, built for the machine that runs the build, so
# that cross-compiling LLVM (e.g. ClangBootstrap) does not have to build them itself.
using BinaryBuilder2

name = "LLVMTblgen"
version = v"17.0.6"

sources = [
    GitSource("https://github.com/llvm/llvm-project.git",
              "6009708b4367171ccdbf4b5905cb6a803753fe18";
              tag="llvmorg-$(version)"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/llvm-project
install_license LICENSE.TXT
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/clang-attr-token-kinds.patch

mkcd ${WORKSPACE}/srcdir/build
cmake ${WORKSPACE}/srcdir/llvm-project/llvm \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_TARGETS_TO_BUILD:STRING=host \
    -DLLVM_ENABLE_PROJECTS='llvm;clang;clang-tools-extra;mlir' \
    -DLLVM_BINDINGS_LIST= \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_ZLIB=FORCE_ON

TBLGEN_TARGETS=(
    llvm-tblgen
    clang-tblgen
    mlir-tblgen
    llvm-config
    mlir-linalg-ods-yaml-gen
    clang-tidy-confusable-chars-gen
    clang-pseudo-gen
    mlir-pdll
)
ninja -j${nproc} "${TBLGEN_TARGETS[@]}"
mkdir -p ${bindir}
for tool in "${TBLGEN_TARGETS[@]}"; do
    cp bin/${tool} ${bindir}/
done
"""

platforms = [Platform("x86_64", "linux")]

products = [
    ExecutableProduct("llvm-tblgen", :llvm_tblgen),
    ExecutableProduct("clang-tblgen", :clang_tblgen),
    ExecutableProduct("mlir-tblgen", :mlir_tblgen),
    ExecutableProduct("llvm-config", :llvm_config),
    ExecutableProduct("mlir-linalg-ods-yaml-gen", :mlir_linalg_ods_yaml_gen),
    ExecutableProduct("clang-tidy-confusable-chars-gen", :clang_tidy_confusable_chars_gen),
    ExecutableProduct("clang-pseudo-gen", :clang_pseudo_gen),
    ExecutableProduct("mlir-pdll", :mlir_pdll),
]

host_dependencies = [
    JLLSource("Python_jll"),
]

target_dependencies = [
    JLLSource("Zlib_jll"; version=v"1.4.1"),
]

host_toolchains = [
    CToolchain(; vendor=:gcc_bootstrap),
    CMakeToolchain(),
    HostToolsToolchain(),
]

target_toolchains = [
    CToolchain(; vendor=:gcc_bootstrap),
    CMakeToolchain(),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host_dependencies,
    target_dependencies,
    host_toolchains,
    target_toolchains,
    julia_compat = "1.8.4",
)
