using BinaryBuilder, Pkg, LibGit2

const llvm_tags = Dict(
    v"17.0.6" => "6009708b4367171ccdbf4b5905cb6a803753fe18",
    v"18.1.3" => "c13b7485b87909fcf739f62cfa382b55407433c0",
)

const buildscript = raw"""
# We want to exit the program if errors occur.
set -o errexit

# Increase max file descriptors
fd_lim=$(ulimit -n -H)
ulimit -n $fd_lim

if [[ ("${target}" == x86_64-apple-darwin*) ]]; then
    # LLVM 15 requires macOS SDK 10.14, see
    # <https://github.com/JuliaPackaging/Yggdrasil/pull/5592#issuecomment-1309525112> and
    # references therein.
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    export MACOSX_DEPLOYMENT_TARGET=10.14
    popd
fi

cd ${WORKSPACE}/srcdir/llvm-project/llvm
LLVM_SRCDIR=$(pwd)

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build && cd ${WORKSPACE}/build

# Accumulate these flags outside CMAKE_FLAGS,
# they will be added at the end.
CMAKE_CPP_FLAGS=()
CMAKE_CXX_FLAGS=()
CMAKE_C_FLAGS=()

CMAKE_FLAGS=()

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
CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS='llvm')
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=False)
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen  llvm-config
popd

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

# build for our host arch
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD:STRING=host)

CMAKE_FLAGS+=(-DLLVM_ENABLE_PROJECTS:STRING=bolt)

# We want a build with no bindings
CMAKE_FLAGS+=(-DLLVM_BINDINGS_LIST="" )

# Turn on ZLIB
CMAKE_FLAGS+=(-DLLVM_ENABLE_ZLIB=ON)
# Turn off XML2
CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBXML2=OFF)

# Disable useless things like docs, terminfo, etc....
CMAKE_FLAGS+=(-DLLVM_INCLUDE_DOCS=Off)
CMAKE_FLAGS+=(-DLLVM_ENABLE_TERMINFO=Off)
CMAKE_FLAGS+=(-DHAVE_LIBEDIT=Off)

# Change this to check if we are building with clang?
if [[ "${bb_full_target}" != *sanitize* && ( "${target}" == *linux* ) ]]; then
    # https://bugs.llvm.org/show_bug.cgi?id=48221
    CMAKE_CXX_FLAGS+=(-fno-gnu-unique)
fi

# Install things into $prefix, and make sure it knows we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=True)

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

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
    CMAKE_FLAGS+=(-DDARWIN_macosx_OVERRIDE_SDK_VERSION:STRING="${MACOSX_DEPLOYMENT_TARGET}")
    # We need to link against libc++ on OSX
    CMAKE_FLAGS+=(-DLLVM_ENABLE_LIBCXX=ON)

    # If we're building for Apple, CMake gets confused with `aarch64-apple-darwin` and instead prefers
    # `arm64-apple-darwin`.  If this issue persists, we may have to change our triplet printing.
    if [[ "${target}" == aarch64* ]]; then
        CMAKE_TARGET=arm64-${target#*-}
    fi

    if [[ "${target}" == x86_64* ]]; then
        CMAKE_FLAGS+=(-DDARWIN_osx_BUILTIN_ARCHS="x86_64")
        CMAKE_FLAGS+=(-DDARWIN_osx_ARCHS="x86_64")
    fi
fi

GCC_VERSION=$(gcc --version | head -1 | awk '{ print $3 }' | cut -d. -f1)
if [[ $version -le 10 && "${target}" == aarch64-linux* ]]; then
    CMAKE_C_FLAGS+=(-mno-outline-atomics)
    CMAKE_CPP_FLAGS+=(-mno-outline-atomics)
fi

# Tell LLVM which compiler target to use, because it loses track for some reason
CMAKE_FLAGS+=(-DCMAKE_C_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_CXX_COMPILER_TARGET=${CMAKE_TARGET})
CMAKE_FLAGS+=(-DCMAKE_ASM_COMPILER_TARGET=${CMAKE_TARGET})

# Set the bug report URL to the Julia issue tracker
CMAKE_FLAGS+=(-DBUG_REPORT_URL="https://github.com/julialang/julia")

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]} -DCMAKE_CXX_FLAGS=\"${CMAKE_CPP_FLAGS[*]} ${CMAKE_CXX_FLAGS[*]}\" -DCMAKE_C_FLAGS=\"${CMAKE_C_FLAGS[*]}\"
ninja -j${nproc} -vv

# Install!
ninja install

install_license ${WORKSPACE}/srcdir/llvm-project/llvm/LICENSE.TXT
"""

function configure_build(ARGS, version; git_path="https://github.com/llvm/llvm-project.git",
    git_ver=llvm_tags[version])

    sources = BinaryBuilder.AbstractSource[GitSource(git_path, git_ver)]
    if version == v"16"
        push!(sources, DirectorySource("./bundled"))
    end

    platforms = expand_cxxstring_abis(supported_platforms())
    filter!(p -> arch(p) ∈ ("i686", "x86_64", "aarch64") && os(p) ∈ ("linux", "macos"), platforms)

    products = [ExecutableProduct("llvm-bolt", :llvm_bolt, "bin")]

    name = "BOLT"
    config = "LLVM_MAJ_VER=$(version.major)\nLLVM_MIN_VER=$(version.minor)\nLLVM_PATCH_VER=$(version.patch)\n"

    # Dependencies that must be installed before this package can be built
    # TODO: LibXML2
    dependencies = [
        Dependency("Zlib_jll"), # for LLD&LTO
    ]
    push!(sources,
        ArchiveSource(
            "https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.14.sdk.tar.xz",
            "0f03869f72df8705b832910517b47dd5b79eb4e160512602f593ed243b28715f"))
    return name, version, sources, config * buildscript, platforms, products, dependencies
end

version = v"18.1.3"
build_tarballs(ARGS, configure_build(ARGS, version)...;
               preferred_gcc_version=v"10", preferred_llvm_version=v"16", julia_compat="1.12")