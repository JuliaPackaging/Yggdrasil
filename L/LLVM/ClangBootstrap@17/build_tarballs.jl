# Clang, LLD and libLLVM built with GCC, which BinaryBuilder2's `:clang_bootstrap` C toolchain
# uses as its compiler.  One build produces two JLLs: `LLVMBootstrap_Clang_jll` (clang, lld,
# libclang, headers) and `LLVMBootstrap_libLLVM_jll` (the shared libLLVM it links against).
using BinaryBuilder2
using BinaryBuilder2: BuildTargetSpec, get_target_spec_by_name

name = "ClangBootstrap"
version = v"17.0.6"

sources = [
    GitSource("https://github.com/llvm/llvm-project.git",
              "6009708b4367171ccdbf4b5905cb6a803753fe18"),
    DirectorySource("./bundled"),
]

script = """
LLVM_MAJ_VER="$(version.major)"
LLVM_MIN_VER="$(version.minor)"
""" * raw"""
LLVM_SRCDIR=${WORKSPACE}/srcdir/llvm-project/llvm
install_license ${WORKSPACE}/srcdir/llvm-project/LICENSE.TXT

# The uname wrapper confuses LLVM's build
rm -f $(which uname)

cd ${WORKSPACE}/srcdir/llvm-project
for patch in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 "${patch}"
done

mkcd ${WORKSPACE}/srcdir/llvm_build

CMAKE_FLAGS=(
    -GNinja
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_BUILD_TYPE=Release

    # Use the tablegen tools from LLVMTblgen_jll, which run on the build machine
    -DLLVM_TABLEGEN=${build_prefix}/bin/llvm-tblgen
    -DCLANG_TABLEGEN=${build_prefix}/bin/clang-tblgen
    -DLLVM_CONFIG_PATH=${build_prefix}/bin/llvm-config
    -DLLVM_NATIVE_TOOL_DIR=${build_prefix}/bin

    -DLLVM_TARGETS_TO_BUILD:STRING='X86;ARM;AArch64;PowerPC;RISCV;WebAssembly'
    -DLLVM_ENABLE_PROJECTS='clang;lld'

    # Build and link against a shared libLLVM
    -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON
    -DLLVM_LINK_LLVM_DYLIB:BOOL=ON
    # SONAME suffix, see https://github.com/JuliaLang/julia/issues/32462
    -DLLVM_VERSION_SUFFIX:STRING="jl"
    -DLLVM_SHLIB_SYMBOL_VERSION:STRING="JL_LLVM_${LLVM_MAJ_VER}.${LLVM_MIN_VER}"
    # Keep the source checkout's path out of `clang --version`
    -DLLVM_APPEND_VC_REV=OFF

    # Turn off bindings, docs, examples, benchmarks and optional dependencies
    -DLLVM_BINDINGS_LIST=
    -DLLVM_INCLUDE_DOCS=OFF
    -DLLVM_INCLUDE_EXAMPLES=OFF
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLLVM_ENABLE_LIBEDIT=OFF
    -DLLVM_ENABLE_TERMINFO=OFF
    -DLLVM_ENABLE_LIBXML2=OFF
    -DLLVM_HAVE_LIBXAR=OFF
    -DLLVM_ENABLE_ZLIB=FORCE_ON
)

export LDFLAGS="-L${host_shlibdir} -Wl,-rpath-link,${host_shlibdir}"

$HOST_CMAKE ${LLVM_SRCDIR} "${CMAKE_FLAGS[@]}"
ninja -j${nproc}
ninja install
"""

# Built for the machines BinaryBuilder2 itself runs on; the compilers target every platform
# through `LLVM_TARGETS_TO_BUILD`, so the target side of each platform is `AnyPlatform()`.
host_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"),
]
platforms = [CrossPlatform(host => AnyPlatform()) for host in host_platforms]

function clang_build_spec_generator(host, platform)
    return [
        BuildTargetSpec(
            "build",
            CrossPlatform(host => host),
            [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain(), HostToolsToolchain()],
            [
                JLLSource("Python_jll"),
                JLLSource("LLVMTblgen_jll"; version=v"17.0.0"),
            ],
            [],
            Set([:native]),
        ),
        BuildTargetSpec(
            "host",
            CrossPlatform(host => platform.host),
            [CToolchain(;vendor=:gcc_bootstrap), CMakeToolchain()],
            [JLLSource("Zlib_jll"; version=v"1.4.1")],
            [],
            Set([:default]),
        ),
        BuildTargetSpec(
            "target",
            platform,
            [],
            [],
            [],
            Set{Symbol}(),
        ),
    ]
end

function clang_extract_spec_generator(build, platform)
    return [
        ExtractSpec(
            raw"""
            extract ${prefix}/**
            rm -f ${extract_dir}/lib/libLLVM*
            rm -f ${extract_dir}/lib/libLTO*
            """,
            [
                ExecutableProduct("clang", :clang),
                ExecutableProduct("clang++", :clangxx),
                LibraryProduct("libclang", :libclang),
                LibraryProduct("libclang-cpp", :libclang_cpp),
            ],
            get_target_spec_by_name(build, "host");
            jll_name = "LLVMBootstrap_Clang",
            platform,
            inter_deps = ["LLVMBootstrap_libLLVM"],
        ),
        ExtractSpec(
            raw"""
            extract ${shlibdir}/libLLVM*
            extract ${shlibdir}/libLTO*
            """,
            [
                LibraryProduct(["libLLVM", "libLLVM-$(version.major)jl"], :libLLVM),
            ],
            get_target_spec_by_name(build, "host");
            jll_name = "LLVMBootstrap_libLLVM",
            platform = platform.host,
        ),
    ]
end

build_tarballs(;
    src_name = name,
    src_version = version,
    sources,
    script,
    platforms,
    build_spec_generator = clang_build_spec_generator,
    extract_spec_generator = clang_extract_spec_generator,
    julia_compat = "1.8.4",
)
