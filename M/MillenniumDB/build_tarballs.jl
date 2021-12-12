# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MillenniumDB"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MillenniumDB/MillenniumDB.git", "b1df3251fa1e51ad160cae1e0a57553da93724be"),  # TODO: use main branch, this is a temporary fix
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MillenniumDB

if [[ "${target}" == x86_64-* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/remove-flags.patch
    if [[ "${target}" == x86_64-apple-darwin* ]]; then
        export CXXFLAGS="-mmacosx-version-min=10.15"
    fi
elif [[ "${target}" == i686-* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/remove-flags.patch
elif [[ "${target}" == aarch64-* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/remove-flags-aarch.patch
fi


cmake -H. -B$prefix -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# filter!(p -> Sys.islinux(p) & (arch(p) == "x86_64"), platforms)
platforms = expand_cxxstring_abis(platforms)
filter!(x -> cxxstring_abi(x) != "cxx03", platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("server", :server),
    ExecutableProduct("query", :query),
    ExecutableProduct("create_db", :create_db), 
    ExecutableProduct("check_bpts", :check_bpts), 
    ExecutableProduct("check_extendible_hash", :check_extendible_hash), 
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("boost_jll"; compat="=1.76"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
