# libtapi, from tpoechtrager's port of Apple's TAPI library, which lets `ld64` from CCTools
# link against the `.tbd` text stubs in the macOS SDK.
using BinaryBuilder2

name = "libtapi"
version = v"1300.6.5"

sources = [
    GitSource("https://github.com/tpoechtrager/apple-libtapi",
              "b8c5ac40267aa5f6004dd38cc2b2cd84f2d9d555"),
]

script = raw"""
TAPIDIR="${WORKSPACE}/srcdir/apple-libtapi"
install_license ${TAPIDIR}/LICENSE.*
mkcd ${TAPIDIR}/build

cmake ${TAPIDIR}/src/llvm \
    -G "Ninja" \
    -DCMAKE_CXX_FLAGS="-I${TAPIDIR}/src/llvm/projects/clang/include -I${TAPIDIR}/build/projects/clang/include" \
    -DLLVM_ENABLE_PROJECTS="tapi;clang" \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DCMAKE_BUILD_TYPE=RELEASE \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DLLVM_TABLEGEN=${host_prefix}/bin/llvm-tblgen \
    -DCLANG_TABLEGEN=${host_prefix}/bin/clang-tblgen
ninja install-libtapi install-tapi-headers
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]

products = [
    LibraryProduct("libtapi", :libtapi),
]

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    products,
    host_dependencies = [
        JLLSource("Python_jll"),
        JLLSource("LibTAPITblgen_jll"),
    ],
    target_dependencies = [JLLSource("Zlib_jll"; version=v"1.4.1")],
    host_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain(), HostToolsToolchain()],
    target_toolchains = [CToolchain(;vendor=:clang_bootstrap), CMakeToolchain()],
)
