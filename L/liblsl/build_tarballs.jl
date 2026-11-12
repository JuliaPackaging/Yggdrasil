# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "liblsl"
version = v"1.16.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sccn/liblsl", "6ca188c266c21f7228dc67077303fa6abaf2e8be"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/liblsl

# Add license file
install_license LICENSE

options=(
    -DCMAKE_BUILD_TYPE=Release 
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
)
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # We need at least MacOS 10.12 for `shared_mutex`
    export MACOSX_DEPLOYMENT_TARGET=10.12
    # LTO doesn't work. Somehow we're compiling with LLVM 18, and libLTO is from LLVM 8, and that mismatch causes a linker error.
    options+=(-DLSL_OPTIMIZATIONS=OFF)
fi

cmake -Bbuild ${options[@]}
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# Our musl (1.1.19) does not support `pthread_getname_np`. (musl 1.2.0 would introduce it.)
filter!(p -> libc(p) != "musl", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("liblsl", :liblsl),
    ExecutableProduct("lslver", :lslver)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
