# LLVMBuilder -- reliable LLVM builds all the time.
using BinaryBuilder, Pkg, LibGit2
using BinaryBuilderBase: get_addable_spec, sanitize

# Everybody is just going to use the same set of platforms

const llvm_tags = Dict(
    v"6.0.1" => "d359f2096850c68b708bc25a7baca4282945949f",
    v"8.0.1" => "19a71f6bdf2dddb10764939e7f0ec2b98dba76c9",
    v"9.0.1" => "c1a0a213378a458fbea1a5c77b315c7dce08fd05",
    v"10.0.1" => "ef32c611aa214dea855364efd7ba451ec5ec3f74",
    v"11.0.0" => "176249bd6732a8044d457092ed932768724a6f06",
    v"11.0.1" => "43ff75f2c3feef64f9d73328230d34dac8832a91",
    v"12.0.0" => "d28af7c654d8db0b68c175db5ce212d74fb5e9bc",
    v"12.0.1" => "980d2f60a8524c5546397db9e8bbb7d6ea56c1b7", # julia-12.0.1-4
    v"13.0.1" => "8a2ae8c8064a0544814c6fac7dd0c4a9aa29a7e6", # julia-13.0.1-3
    v"14.0.6" => "b29f34222ebe84265e1e794ff3825a3afeeb233d", # julia-14.0.6-2
)

const buildscript = raw"""
# We want to exit the program if errors occur.
set -o errexit

if [[ ${bb_full_target} == *-sanitize+memory* ]]; then
    # Install msan runtime (for clang)
    cp -rL ${prefix}/lib/linux/* /opt/x86_64-linux-musl/lib/clang/*/lib/linux/
fi

if [[ ${target} == *mingw32* ]]; then
    export CCACHE_DISABLE=true
fi

cd ${WORKSPACE}/srcdir/llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Apply all our patches
if [ -d $WORKSPACE/srcdir/llvm_patches ]; then
for f in $WORKSPACE/srcdir/llvm_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/clang_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/clang
for f in $WORKSPACE/srcdir/clang_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/crt_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/compiler-rt
for f in $WORKSPACE/srcdir/crt_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

if [ -d $WORKSPACE/srcdir/libcxx_patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project/libcxx
for f in $WORKSPACE/srcdir/libcxx_patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

# Patches from the monorepo
if [ -d $WORKSPACE/srcdir/patches ]; then
cd ${WORKSPACE}/srcdir/llvm-project
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/

# Build llvm-tblgen, clang-tblgen, and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${LLVM_MAJ_VER}" -gt "11" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang;mlir')
else
    CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm;clang')
fi
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
if [[ ("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    ninja -j${nproc} llvm-tblgen clang-tblgen mlir-tblgen llvm-config
else
    ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
fi
if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
    ninja -j${nproc} mlir-linalg-ods-gen
fi
if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
    ninja -j${nproc} mlir-linalg-ods-yaml-gen
fi
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=""
CMAKE_CXX_FLAGS=""
CMAKE_C_FLAGS=""

CMAKE_FLAGS=()

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${ASSERTS}" == "1" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS:BOOL=ON)
fi

# build for our host arch and our GPU targets NVidia and AMD
TARGETS=(host NVPTX AMDGPU)
# Add WASM and BPF for LLVM >6
if [[ "${LLVM_MAJ_VER}" != "6" ]]; then
    TARGETS+=(WebAssembly BPF)
fi
LLVM_TARGETS=$(IFS=';' ; echo "${TARGETS[*]}")
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=$LLVM_TARGETS)

# We mostly care about clang and LLVM
PROJECTS=(llvm clang clang-tools-extra compiler-rt lld)
if [[ ("${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0") || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    PROJECTS+=(mlir)
fi
LLVM_PROJECTS=$(IFS=';' ; echo "${PROJECTS[*]}")
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS:STRING=$LLVM_PROJECTS)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST="" )

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

# We want a shared library
if [ -z "${LLVM_WANT_STATIC}" ]; then
    CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON)
    CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
    # set a SONAME suffix for FreeBSD https://github.com/JuliaLang/julia/issues/32462
    CMAKE_FLAGS+=(-DLLVM_VERSION_SUFFIX:STRING="jl")
    # Aggressively symbol version (added in LLVM 13.0.1)
    CMAKE_FLAGS+=(-DLLVM_SHLIB_SYMBOL_VERSION:STRING="JL_LLVM_${LLVM_MAJ_VER}.${LLVM_MIN_VER}")
fi

if [[ "${bb_full_target}" != *sanitize* && ( "${target}" == *linux* || "${target}" == *mingw* ) ]]; then
    # https://bugs.llvm.org/show_bug.cgi?id=48221
    CMAKE_CXX_FLAGS+="-fno-gnu-unique"
fi

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Julia expects the produced LLVM tools to be installed into tools and not bin
# We can't simply move bin to tools since on MingW64 it will also contain the shlib.
CMAKE_FLAGS+=(-DLLVM_TOOLS_INSTALL_DIR="tools")

# Also build and install utils, since we want FileCheck, and lit
CMAKE_FLAGS+=(-DLLVM_UTILS_INSTALL_DIR="tools")
CMAKE_FLAGS+=(-DLLVM_INCLUDE_UTILS=True -DLLVM_INSTALL_UTILS=True)

# Include perf/oprofile/vtune markers
if [[ ${target} == *linux* ]]; then
    CMAKE_FLAGS+=(-DLLVM_USE_PERF=1)
#     CMAKE_FLAGS+=(-DLLVM_USE_OPROFILE=1)
fi
# if [[ ${target} == *linux* ]] || [[ ${target} == *mingw32* ]]; then
if [[ ${target} == *linux* ]]; then # TODO only LLVM12
    CMAKE_FLAGS+=(-DLLVM_USE_INTEL_JITEVENTS=1)
fi


if [[ "${LLVM_MAJ_VER}" -ge "14" ]]; then
    CMAKE_FLAGS+=(-DLLVM_WINDOWS_PREFER_FORWARD_SLASH=False)
fi

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)
if [[ ( "${LLVM_MAJ_VER}" -eq "12" && "${LLVM_PATCH_VER}" -gt "0" ) || "${LLVM_MAJ_VER}" -gt "12" ]]; then
    CMAKE_FLAGS+=(-DMLIR_TABLEGEN=${WORKSPACE}/bootstrap/bin/mlir-tblgen)
fi
if [[ ("${LLVM_MAJ_VER}" -eq "12") || ("${LLVM_MAJ_VER}" -eq "13") ]]; then
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-gen)
fi
if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
    CMAKE_FLAGS+=(-DMLIR_LINALG_ODS_YAML_GEN=${WORKSPACE}/bootstrap/bin/mlir-linalg-ods-yaml-gen)
fi

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${target})

# Most targets use the actual target string, but we disagree on `aarch64-darwin` and `arm64-darwin`
CMAKE_TARGET=${target}

if [[ "${target}" == *apple* ]]; then
    # On OSX, we need to override LLVM's looking around for our SDK
    CMAKE_FLAGS+=(-DDARWIN_macosx_CACHED_SYSROOT:STRING=/opt/${target}/${target}/sys-root)
    CMAKE_FLAGS+=(-DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING=10.8)

    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)

    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi

    if [[ "${LLVM_MAJ_VER}" -gt "12" ]]; then
        CMAKE_FLAGS+=(-DLLVM_HAVE_LIBXAR=OFF)
    fi
fi

if [[ "${target}" == *apple* ]] || [[ "${target}" == *freebsd* ]]; then
    # On clang-based platforms we need to override the check for ffs because it doesn't work with `clang`.
    export ac_cv_have_decl___builtin_ffs=yes

    # We don't use X-ray on BSD systems
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *mingw* ]]; then
    CMAKE_CPP_FLAGS="${CMAKE_CPP_FLAGS} -remap -D__USING_SJLJ_EXCEPTIONS__ -D__CRT__NO_INLINE"
    # Windows is case-insensitive and some dependencies take full advantage of that
    echo "BaseTsd.h basetsd.h" >> /opt/${target}/${target}/include/header.gcc
    CMAKE_FLAGS+=(-DCLANG_INCLUDE_TESTS=OFF)
fi

CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=OFF)
if [[ "${target}" == *musl* ]]; then
    # Taken from https://git.alpinelinux.org/cgit/aports/tree/main/compiler-rt/APKBUILD
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *freebsd* ]]; then
    # On FreeBSD, we must force even statically-linked code to have -fPIC
    CMAKE_FLAGS+=(-DCMAKE_POSITION_INDEPENDENT_CODE=TRUE)
fi

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_TARGET})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}"
ninja -j${nproc} -vv

# Install!
ninja install

# Life is harsh on Windows and dynamic libraries are
# expected to live alongside the binaries. So we have
# to copy the *.dll from bin/ to tools/ as well...
if [[ "${target}" == *mingw* ]]; then
    cp ${prefix}/bin/*.dll ${prefix}/tools/
fi

# Work around llvm-config bug by creating versioned symlink to libLLVM
# https://github.com/JuliaLang/julia/pull/30033
if [[ "${target}" == *darwin* ]]; then
    LLVM_VER=$(${WORKSPACE}/bootstrap/bin/llvm-config --version | cut -d. -f1-2)
    ln -s libLLVM.dylib ${prefix}/lib/libLLVM-${LLVM_VER}.dylib
fi

# Lit is a python dependency and there is no proper install target
cp -r ${LLVM_SRCDIR}/utils/lit ${prefix}/tools/

install_license ${WORKSPACE}/srcdir/llvm-project/llvm/LICENSE.TXT
"""

# Also define some scripts for extraction:
const libllvmscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `llvm-config`, `libLLVM` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/include/llvm* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/llvm-config* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*LLVM*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/*LLVM*.a ${prefix}/lib
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const clangscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `clang`, `libclang` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/bin ${libdir} ${prefix}/lib ${prefix}/tools
mv -v ${LLVM_ARTIFACT_DIR}/include/clang* ${prefix}/include/
if [[ -f ${LLVM_ARTIFACT_DIR}/bin/clang* ]]; then
    mv -v ${LLVM_ARTIFACT_DIR}/bin/clang* ${prefix}/tools/
else
    mv -v ${LLVM_ARTIFACT_DIR}/tools/clang* ${prefix}/tools/
fi
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/libclang*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/libclang*.a ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/lib/clang ${prefix}/lib/clang
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v13 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))
# Clear out our `${prefix}`
rm -rf ${prefix}/*
# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/mlir* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const mlirscript_v14 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `libMLIR` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir} ${prefix}/lib
mv -v ${LLVM_ARTIFACT_DIR}/include/mlir* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/mlir* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*MLIR*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*mlir*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/objects-Release ${prefix}/lib/
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const lldscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over `lld`, `libclang` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/bin ${libdir} ${prefix}/lib ${prefix}/tools
mv -v ${LLVM_ARTIFACT_DIR}/include/lld* ${prefix}/include/
if [[ -f ${LLVM_ARTIFACT_DIR}/bin/lld* ]]; then
    mv -v ${LLVM_ARTIFACT_DIR}/bin/*lld* ${prefix}/tools/
    mv -v ${LLVM_ARTIFACT_DIR}/bin/wasm-ld* ${prefix}/tools/
else
    mv -v ${LLVM_ARTIFACT_DIR}/tools/*lld* ${prefix}/tools/
    mv -v ${LLVM_ARTIFACT_DIR}/tools/wasm-ld* ${prefix}/tools/
fi
# mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/liblld*.${dlext}* ${libdir}/
mv -v ${LLVM_ARTIFACT_DIR}/lib/liblld*.a ${prefix}/lib
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full*/*
"""

const llvmscript_v13 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))
# Clear out our `${prefix}`
rm -rf ${prefix}/*
# Copy over everything, but eliminate things already put inside `Clang_jll` or `libLLVM_jll`:
mv -v ${LLVM_ARTIFACT_DIR}/* ${prefix}/
rm -vrf ${prefix}/include/{clang*,llvm*,mlir*}
rm -vrf ${prefix}/bin/{clang*,llvm-config,mlir*}
rm -vrf ${prefix}/tools/{clang*,llvm-config,mlir*}
rm -vrf ${libdir}/libclang*.${dlext}*
rm -vrf ${libdir}/*LLVM*.${dlext}*
rm -vrf ${libdir}/*MLIR*.${dlext}*
rm -vrf ${prefix}/lib/*LLVM*.a
rm -vrf ${prefix}/lib/libclang*.a
rm -vrf ${prefix}/lib/clang
rm -vrf ${prefix}/lib/mlir
# Move lld to tools/
mv -v "${bindir}/lld${exeext}" "${prefix}/tools/lld${exeext}"
"""

const llvmscript_v14 = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over everything, but eliminate things already put inside `Clang_jll` or `libLLVM_jll`:
mv -v ${LLVM_ARTIFACT_DIR}/* ${prefix}/
rm -vrf ${prefix}/include/{*lld*,clang*,llvm*,mlir*}
rm -vrf ${prefix}/bin/{*lld*,wasm-ld*,clang*,llvm-config,mlir*}
rm -vrf ${prefix}/tools/{*lld*,wasm-ld*,clang*,llvm-config,mlir*}
rm -vrf ${libdir}/libclang*.${dlext}*
rm -vrf ${libdir}/*LLD*.${dlext}*
rm -vrf ${libdir}/*LLVM*.${dlext}*
rm -vrf ${libdir}/*MLIR*.${dlext}*
rm -vrf ${prefix}/lib/*LLVM*.a
rm -vrf ${prefix}/lib/libclang*.a
rm -vrf ${prefix}/lib/clang
rm -vrf ${prefix}/lib/mlir
rm -vrf ${prefix}/lib/lld
rm -vrf {prefix}/lib/objects-Release
"""

function configure_build(ARGS, version; experimental_platforms=false, assert=false,
                         git_path="https://github.com/JuliaLang/llvm-project.git",
                         git_ver=llvm_tags[version], custom_name=nothing,
                         custom_version=version, static=false, platform_filter=nothing)
    # Parse out some args
    if "--assert" in ARGS
        assert = true
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    end
    sources = [
        GitSource(git_path, git_ver),
        DirectorySource("./bundled"),
    ]

    platforms = expand_cxxstring_abis(supported_platforms(;experimental=experimental_platforms))
    if platform_filter !== nothing
        platforms = filter(platform_filter, platforms)
    end
    products = [
        LibraryProduct("libclang", :libclang, dont_dlopen=true),
        LibraryProduct(["LTO", "libLTO"], :liblto, dont_dlopen=true),
        ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ExecutableProduct(["clang", "clang-$(version.major)"], :clang, "tools"),
        ExecutableProduct("opt", :opt, "tools"),
        ExecutableProduct("llc", :llc, "tools"),
    ]
    if !static
        push!(products, LibraryProduct(["LLVM", "libLLVM", "libLLVM-$(version.major)jl"], :libllvm, dont_dlopen=true))
    end
    if version >= v"8"
        push!(products, ExecutableProduct("llvm-mca", :llvm_mca, "tools"))
    end
    if v"12" < version < v"13"
        push!(products, LibraryProduct(["MLIRPublicAPI", "libMLIRPublicAPI"], :mlir_public, dont_dlopen=true))
    end
    if version >= v"12.0.1"
        push!(products, LibraryProduct(["MLIR", "libMLIR"], :mlir, dont_dlopen=true))
    end
    if version >= v"12"
        push!(products, LibraryProduct("libclang-cpp", :libclang_cpp, dont_dlopen=true))
        push!(products, ExecutableProduct("lld", :lld, "tools"))
        push!(products, ExecutableProduct("ld.lld", :ld_lld, "tools"))
        push!(products, ExecutableProduct("ld64.lld", :ld64_lld, "tools"))
        push!(products, ExecutableProduct("lld-link", :lld_link, "tools"))
        push!(products, ExecutableProduct("wasm-ld", :wasm_ld, "tools"))
    end

    name = "LLVM_full"
    config = "LLVM_MAJ_VER=$(version.major)\nLLVM_MIN_VER=$(version.minor)\nLLVM_PATCH_VER=$(version.patch)\n"
    if static
        config *= "LLVM_WANT_STATIC=1\n"
    end
    if assert
        config *= "ASSERTS=1\n"
        name = "$(name)_assert"
    end
    if custom_name !== nothing
        name = custom_name
    end
    # Dependencies that must be installed before this package can be built
    # TODO: LibXML2
    dependencies = [
        Dependency("Zlib_jll"), # for LLD&LTO
        BuildDependency("LLVMCompilerRT_jll"; platforms=filter(p -> sanitize(p)=="memory", platforms)),
    ]
    return name, custom_version, sources, config * buildscript, platforms, products, dependencies
end

function configure_extraction(ARGS, LLVM_full_version, name, libLLVM_version=nothing; experimental_platforms=false, assert=false, augmentation=false)
    if isempty(LLVM_full_version.build)
        error("You must lock an extracted LLVM build to a particular LLVM_full build number!")
    end
    if name != "libLLVM" && (libLLVM_version === nothing || isempty(libLLVM_version.build))
        error("You must lock an extracted LLVM build to a particular libLLVM build number!")
    end
    version = VersionNumber(LLVM_full_version.major, LLVM_full_version.minor, LLVM_full_version.patch)
    compat_version = "$(version.major).$(version.minor).$(version.patch)"
    if name == "libLLVM"
        script = libllvmscript
        products = [
            LibraryProduct(["LLVM", "libLLVM", "libLLVM-$(version.major)jl"], :libllvm, dont_dlopen=true),
            ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ]
    elseif name == "Clang"
        script = clangscript
        products = [
            LibraryProduct("libclang", :libclang, dont_dlopen=true),
            LibraryProduct("libclang-cpp", :libclang_cpp, dont_dlopen=true),
            ExecutableProduct(["clang", "clang-$(version.major)"], :clang, "tools"),
        ]
    elseif name == "MLIR"
        script = version < v"14" ? mlirscript_v13 : mlirscript_v14
        products = [
            LibraryProduct("libMLIR", :libMLIR, dont_dlopen=true),
        ]
        if v"12" <= version < v"13"
            push!(products, LibraryProduct("libMLIRPublicAPI", :libMLIRPublicAPI, dont_dlopen=true))
        end
    elseif name == "LLD"
        script = lldscript
        products = [
            ExecutableProduct("lld", :lld, "tools"),
            ExecutableProduct("ld.lld", :ld_lld, "tools"),
            ExecutableProduct("ld64.lld", :ld64_lld, "tools"),
            ExecutableProduct("lld-link", :lld_link, "tools"),
            ExecutableProduct("wasm-ld", :wasm_ld, "tools"),
        ]
        
    elseif name == "LLVM"
        script = version < v"14" ? llvmscript_v13 : llvmscript_v14
        products = [
            LibraryProduct(["LTO", "libLTO"], :liblto, dont_dlopen=true),
            ExecutableProduct("opt", :opt, "tools"),
            ExecutableProduct("llc", :llc, "tools"),
        ]
        if version >= v"8"
            push!(products, ExecutableProduct("llvm-mca", :llvm_mca, "tools"))
        end
        if v"12" <= version < v"14"
            push!(products, ExecutableProduct("lld", :lld, "tools"))
            push!(products, ExecutableProduct("ld.lld", :ld_lld, "tools"))
            push!(products, ExecutableProduct("ld64.lld", :ld64_lld, "tools"))
            push!(products, ExecutableProduct("lld-link", :lld_link, "tools"))
            push!(products, ExecutableProduct("wasm-ld", :wasm_ld, "tools"))
        end
    end

    platforms = supported_platforms(;experimental=experimental_platforms)
    push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
    platforms = expand_cxxstring_abis(platforms)

    if augmentation
        augmented_platforms = Platform[]
        for platform in platforms
            augmented_platform = deepcopy(platform)
            augmented_platform[LLVM.platform_name] = LLVM.platform(version, assert)

            should_build_platform(triplet(augmented_platform)) || continue
            push!(augmented_platforms, augmented_platform)
        end
        platforms = augmented_platforms
    end

    dependencies = BinaryBuilder.AbstractDependency[
        Dependency("Zlib_jll"), # for LLD&LTO
    ]

    # Parse out some args
    if "--assert" in ARGS
        assert = true
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    end

    if assert
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_assert_jll", LLVM_full_version)))
        if !augmentation
            if name in ("Clang", "LLVM", "MLIR", "LLD")
                push!(dependencies, Dependency("libLLVM_assert_jll", libLLVM_version, compat=compat_version))
            end

            name = "$(name)_assert"
        else
            if name in ("Clang", "LLVM", "MLIR", "LLD")
                push!(dependencies, Dependency("libLLVM_jll", libLLVM_version, compat=compat_version))
            end
        end
    else
        push!(dependencies, BuildDependency(get_addable_spec("LLVM_full_jll", LLVM_full_version)))
        if name in ("Clang", "LLVM", "MLIR", "LLD")
            push!(dependencies, Dependency("libLLVM_jll", libLLVM_version, compat=compat_version))
        end
    end

    return name, version, [], script, platforms, products, dependencies
end
