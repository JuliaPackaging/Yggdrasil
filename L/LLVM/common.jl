# LLVMBuilder -- reliable LLVM builds all the time.
using BinaryBuilder, Pkg, LibGit2

include("../../fancy_toys.jl")

# Everybody is just going to use the same set of platforms
platforms = expand_cxxstring_abis(supported_platforms())

const llvm_tags = Dict(
    v"6.0.1" => "d359f2096850c68b708bc25a7baca4282945949f",
    v"8.0.1" => "19a71f6bdf2dddb10764939e7f0ec2b98dba76c9",
    v"9.0.1" => "c1a0a213378a458fbea1a5c77b315c7dce08fd05",
)

const buildscript = raw"""
# We want to exit the program if errors occur.
set -o errexit

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
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;compiler-rt')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=""
CMAKE_CXX_FLAGS=""
CMAKE_C_FLAGS=""

CMAKE_FLAGS=()

# Release build for best perofrmance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
if [[ "${ASSERTS}" == "1" ]]; then
    CMAKE_FLAGS+=(-DLLVM_ENABLE_ASSERTIONS:BOOL=ON)
fi

# build for our host arch and our GPU targets NVidia and AMD
TARGETS=(host NVPTX AMDGPU)
# Add WASM for LLVM 8
if [[ "${LLVM_MAJ_VER}" == "8" ]]; then
    TARGETS+=(WebAssembly)
fi
LLVM_TARGETS=$(IFS=';' ; echo "${TARGETS[*]}")
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=$LLVM_TARGETS)

# We mostly care about clang and LLVM
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='clang;compiler-rt;lld')
CMAKE_FLAGS+=(-DLLVM_TOOL_CLANG_TOOLS_EXTRA_BUILD=OFF)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST="" )

# Turn off ZLIB and XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=OFF)
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_HISTEDIT_H=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

# We want a shared library
CMAKE_FLAGS+=(-DLLVM_BUILD_LLVM_DYLIB:BOOL=ON)
CMAKE_FLAGS+=(-DLLVM_LINK_LLVM_DYLIB:BOOL=ON)
# set a SONAME suffix for FreeBSD https://github.com/JuliaLang/julia/issues/32462
CMAKE_FLAGS+=(-DLLVM_VERSION_SUFFIX:STRING="jl")

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Julia expects the produced LLVM tools to be installed into tools and not bin
# We can't simply move bin to tools since on MingW64 it will also contain the shlib.
CMAKE_FLAGS+=(-DLLVM_TOOLS_INSTALL_DIR=${prefix}/tools)

# Also build and install utils, since we want FileCheck, and lit
CMAKE_FLAGS+=(-DLLVM_UTILS_INSTALL_DIR=${prefix}/tools)
CMAKE_FLAGS+=(-DLLVM_INCLUDE_UTILS=True -DLLVM_INSTALL_UTILS=True)

# Include perf/oprofile/vtune markers
if [[ ${target} == *linux* ]]; then
    CMAKE_FLAGS+=(-DLLVM_USE_PERF=1)
#     CMAKE_FLAGS+=(-DLLVM_USE_OPROFILE=1)
fi
if [[ ${target} == *linux* ]] || [[ ${target} == *mingw32* ]]; then
    CMAKE_FLAGS+=(-DLLVM_USE_INTEL_JITEVENTS=1)
fi

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Explicitly use our cmake toolchain file
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=/opt/${target}/${target}.cmake)

# Manually set the host triplet, as otherwise on some platforms it tries to guess using
# `ld -v`, which is hilariously wrong.
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${target})

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${target})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${target})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${target})

if [[ "${target}" == *apple* ]]; then
    # On OSX, we need to override LLVM's looking around for our SDK
    CMAKE_FLAGS+=(-DDARWIN_macosx_CACHED_SYSROOT:STRING=/opt/${target}/${target}/sys-root)

    # LLVM actually won't build against 10.8, so we bump ourselves up slightly to 10.9
    export MACOSX_DEPLOYMENT_TARGET=10.9
    export LDFLAGS=-mmacosx-version-min=10.9

    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)
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
fi

if [[ "${target}" == *musl* ]]; then
    # Taken from https://git.alpinelinux.org/cgit/aports/tree/main/compiler-rt/APKBUILD
    CMAKE_FLAGS+=(-DCOMPILER_RT_INCLUDE_TESTS=ON)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_SANITIZERS=OFF)
    CMAKE_FLAGS+=(-DCOMPILER_RT_BUILD_XRAY=OFF)
fi

if [[ "${target}" == *freebsd* ]]; then
    # On FreeBSD, we must force even statically-linked code to have -fPIC
    CMAKE_FLAGS+=(-DCMAKE_POSITION_INDEPENDENT_CODE=TRUE)
fi

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}" -DCMAKE_C_FLAGS="${CMAKE_CPP_FLAGS} ${CMAKE_CXX_FLAGS}"
cmake -LA || true
ninja -j${nproc} -vv

# Install!
ninja install -j${nproc}

# move clang products out of $prefix/bin to $prefix/tools
mv ${prefix}/bin/clang* ${prefix}/tools/
mv ${prefix}/bin/scan-* ${prefix}/tools/
mv ${prefix}/bin/c-index* ${prefix}/tools/
mv ${prefix}/bin/git-clang* ${prefix}/tools/
mv ${prefix}/bin/lld* ${prefix}/tools/

# Life is harsh on Windows and dynamic libraries are
# expected to live alongside the binaries. So we have
# to copy the *.dll from bin/ to tools/ as well...
if [[ "${target}" == *mingw* ]]; then
    cp ${prefix}/bin/*.dll ${prefix}/tools/
fi

# Work around llvm-config bug by creating versioned symlink to libLLVM
# https://github.com/JuliaLang/julia/pull/30033
if [[ "${target}" == *darwin* ]]; then
    LLVM_VER=$(basename $(echo ${prefix}/tools/clang-*.*))
    ln -s libLLVM.dylib ${prefix}/lib/libLLVM-${LLVM_VER##*-}.dylib
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
rm -rf ${prefix}

# Copy over `llvm-config`, `libLLVM` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir}
mv -v ${LLVM_ARTIFACT_DIR}/include/llvm* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/llvm-config* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/*LLVM*.${dlext}* ${libdir}/
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full/*
"""

const clangscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}

# Copy over `clang`, `libclang` and `include`, specifically.
mkdir -p ${prefix}/include ${prefix}/tools ${libdir}
mv -v ${LLVM_ARTIFACT_DIR}/include/clang* ${prefix}/include/
mv -v ${LLVM_ARTIFACT_DIR}/tools/clang* ${prefix}/tools/
mv -v ${LLVM_ARTIFACT_DIR}/$(basename ${libdir})/libclang*.${dlext}* ${libdir}/
install_license ${LLVM_ARTIFACT_DIR}/share/licenses/LLVM_full/*
"""

const llvmscript = raw"""
# First, find (true) LLVM library directory in ~/.artifacts somewhere
LLVM_ARTIFACT_DIR=$(dirname $(dirname $(realpath ${prefix}/tools/opt${exeext})))

# Clear out our `${prefix}`
rm -rf ${prefix}/*

# Copy over everything, but eliminate things already put inside `Clang_jll` or `libLLVM_jll`:
mv -v ${LLVM_ARTIFACT_DIR}/* ${prefix}/
rm -vrf ${prefix}/include/{clang*,llvm*}
rm -vrf ${prefix}/tools/{clang*,llvm-config}
rm -vrf ${libdir}/libclang*.${dlext}*
rm -vrf ${libdir}/*LLVM*.${dlext}*
"""

function configure_build(ARGS, version)
    # Parse out some args
    assert = false
    if "--assert" in ARGS
        assert = true
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    end
    sources = [
        GitSource("https://github.com/llvm/llvm-project.git", llvm_tags[version]),
        DirectorySource("./bundled"),
    ]

    products = [
        LibraryProduct("libclang", :libclang, dont_dlopen=true),
        LibraryProduct(["LLVM", "libLLVM"], :libllvm, dont_dlopen=true),
        LibraryProduct(["LTO", "libLTO"], :liblto, dont_dlopen=true),
        ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ExecutableProduct("clang", :clang, "tools"),
        ExecutableProduct("opt", :opt, "tools"),
        ExecutableProduct("llc", :llc, "tools"),
    ]
    if version >= v"8"
        push!(products, ExecutableProduct("llvm-mca", :llvm_mca, "tools"))
    end

    name = "LLVM_full"
    config = "LLVM_MAJ_VER=$(version.major)\n"
    if assert
        config *= "ASSERTS=1\n"
        name = "$(name)_assert"
    end
    # Dependencies that must be installed before this package can be built
    # TODO: Zlib, LibXML2
    dependencies = Dependency[]
    return name, version, sources, config * buildscript, platforms, products, dependencies
end

function configure_extraction(ARGS, version_with_build, name)
    if name != "libLLVM" && isempty(version_with_build.build)
        error("You must lock an extracted LLVM build to a particular libLLVM build number!")
    end
    version = VersionNumber(version_with_build.major, version_with_build.minor, version_with_build.patch)
    if name == "libLLVM"
        script = libllvmscript
        products = [
            LibraryProduct(["LLVM", "libLLVM"], :libllvm, dont_dlopen=true),
            ExecutableProduct("llvm-config", :llvm_config, "tools"),
        ]
    elseif name == "Clang"
        script = clangscript
        products = [
            LibraryProduct("libclang", :libclang, dont_dlopen=true),
            ExecutableProduct("clang", :clang, "tools"),
        ]
    elseif name == "LLVM"
        script = llvmscript
        products = [
            LibraryProduct(["LTO", "libLTO"], :liblto, dont_dlopen=true),
            ExecutableProduct("opt", :opt, "tools"),
            ExecutableProduct("llc", :llc, "tools"),
        ]
    end

    dependencies = BinaryBuilder.AbstractDependency[]
    if "--assert" in ARGS
        push!(dependencies, BuildDependency(PackageSpec(name="LLVM_full_assert_jll", version=version)))
        if name in ("Clang", "LLVM")
            push!(dependencies, Dependency(get_addable_spec("libLLVM_assert_jll", version_with_build)))
        end
        name = "$(name)_assert"
        deleteat!(ARGS, findfirst(ARGS .== "--assert"))
    else
        push!(dependencies, BuildDependency(PackageSpec(name="LLVM_full_jll", version=version)))
        if name in ("Clang", "LLVM")
            push!(dependencies, Dependency(get_addable_spec("libLLVM_jll", version_with_build)))
        end
    end

    return name, version, [], script, platforms, products, dependencies
end


