# `llvm-tblgen` and `clang-tblgen` from Apple's LLVM fork as used by libtapi, which needs
# versions of them that run on the build machine in order to cross-compile.
using BinaryBuilder2

name = "LibTAPITblgen"
version = v"1300.6.5"

sources = [
    GitSource("https://github.com/tpoechtrager/apple-libtapi",
              "b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"),
]

script = raw"""
TAPIDIR="${WORKSPACE}/srcdir/apple-libtapi"
install_license ${TAPIDIR}/LICENSE.*
mkcd ${TAPIDIR}/build
${HOST_CMAKE} ${TAPIDIR}/src/llvm \
    -G "Ninja" \
    -DLLVM_TARGETS_TO_BUILD:STRING=host \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DLLVM_ENABLE_PROJECTS="clang;llvm" \
    -DCMAKE_CROSSCOMPILING=False \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCMAKE_INSTALL_PREFIX=${prefix}
ninja llvm-tblgen clang-tblgen
mkdir -p ${bindir}
cp bin/*-tblgen ${bindir}/
"""

platforms = [Platform("x86_64", "linux")]

products = [
    ExecutableProduct("llvm-tblgen", :llvm_tblgen),
    ExecutableProduct("clang-tblgen", :clang_tblgen),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host_dependencies = [JLLSource("Python_jll")],
    target_dependencies = [JLLSource("Zlib_jll"; version=v"1.4.1")],
    host_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain()],
)
