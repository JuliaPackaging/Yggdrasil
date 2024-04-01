# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# Cling is an interactive C++ interpreter,
# built on the top of LLVM and Clang libraries.
# https://root.cern/cling

name = "Cling"
version = v"0.9.0"

# Collection of sources required to complete build
# Cling requires CERN's patched versions of llvm and clang.
sources = [
    GitSource("http://root.cern/git/llvm.git",
              "859a19cc70aba64df3a20f1b91c84b81547bbf24"), # tag: cling-v0.9
    GitSource("http://root.cern/git/clang.git",
              "0e0d27eb409f64af84cc6a85c2fb48d2b5ce8122"), # tag: cling-v0.9
    GitSource("http://root.cern/git/cling.git",
              "646e3f59550b6a24d81edde5694844a1a8c3fdf4"), # tag: v0.9
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
# Cling Build Instructions: https://root.cern/cling/cling_build_instructions/
# Cling Homebrew Formula: https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/cling.rb
script = raw"""
cd $WORKSPACE/srcdir
mv llvm/ src
mv clang/ src/tools/
mv cling/ src/tools/

LLVM_SRCDIR=$(pwd)/src

# Patch to work-around missing clang runtime lib
# (undefined symbol ___isPlatformVersionAtLeast).
# See: https://github.com/JuliaPackaging/Yggdrasil/pull/5937#issuecomment-1334463175
pushd ${LLVM_SRCDIR}
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/*
popd

cp src/LICENSE.TXT LICENSE_LLVM.TXT 
cp src/tools/clang/LICENSE.TXT LICENSE_CLANG.TXT 
cp src/tools/cling/LICENSE.TXT LICENSE_CLING.TXT 
install_license LICENSE_LLVM.TXT 
install_license LICENSE_CLANG.TXT 
install_license LICENSE_CLING.TXT 

# The very first thing we need to do is to build llvm-tblgen for x86_64-linux-muslc
# This is because LLVM's cross-compile setup is kind of borked, so we just
# build the tools natively ourselves, directly.  :/
# See: https://github.com/JuliaPackaging/Yggdrasil/blob/86a4221f71ee8ca5c0fd1056829a1fe2b28c879b/M/Metal_LLVM_Tools/build_tarballs.jl#L35

# Build llvm-tblgen and llvm-config
mkdir ${WORKSPACE}/bootstrap
pushd ${WORKSPACE}/bootstrap
CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DLLVM_TARGETS_TO_BUILD="host;NVPTX")
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=OFF)
cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} llvm-tblgen clang-tblgen llvm-config
popd

# Let's do the actual build within the `build` subdirectory
mkdir ${WORKSPACE}/build
cd ${WORKSPACE}/build

CMAKE_FLAGS=()

# Tell LLVM where our pre-built tblgen tools are
CMAKE_FLAGS+=(-DLLVM_TABLEGEN=${WORKSPACE}/bootstrap/bin/llvm-tblgen)
CMAKE_FLAGS+=(-DCLANG_TABLEGEN=${WORKSPACE}/bootstrap/bin/clang-tblgen)
CMAKE_FLAGS+=(-DLLVM_CONFIG_PATH=${WORKSPACE}/bootstrap/bin/llvm-config)

# Install things into $prefix
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})

# Explicitly use our cmake toolchain file and tell CMake we're cross-compiling
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DCMAKE_CROSSCOMPILING=ON)

if [[ "${target}" == *apple* ]]; then
    # Without this, cling will try to call `x86_64-apple-darwin14-clang++`
    # on the macOS machine to find C++ header locations.
    CMAKE_FLAGS+=(-DCLING_CXX_PATH=clang++)
fi

# Release build for best performance
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)

cmake -GNinja ${LLVM_SRCDIR} ${CMAKE_FLAGS[@]}
ninja -j${nproc} \
    tools/cling/install \
    install-clang-resource-headers
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;exclude=x->
    startswith(arch(x), r"arm|power") ||
    Sys.isfreebsd(x) ||
    Sys.iswindows(x) ||
    (Sys.isapple(x) && arch(x) == "aarch64"))
    # FreeBSD build failed with:
    #   libc.so.7: undefined reference to `__progname', `environ`
    #
    # Windows build failed with:
    #   TCHAR.H, Shlwapi.h: No such file or directory
    #
    # aarch64 macOS failed with:
    #   The C compiler is not able to compile a simple test program.
    #
    # Failed build Logs:
    # https://dev.azure.com/JuliaPackaging/Yggdrasil/_build/results?buildId=23989&view=results
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcling", :libcling),
    ExecutableProduct("cling", :cling)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
# Compiler versions taken from here:
# https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/LLVM/LLVM_full%409.0.1/build_tarballs.jl
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    preferred_gcc_version=v"7",
    preferred_llvm_version=v"8")
