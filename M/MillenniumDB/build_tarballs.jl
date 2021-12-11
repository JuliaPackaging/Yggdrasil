# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MillenniumDB"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/MillenniumDB/MillenniumDB.git", "cd387153d9bb73bce8dd2f2f18e504ac0b308a3d"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/MillenniumDB
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/remove-flags.patch

# # See if a patch from Yggdrasil/C/Coin-OR/SHOT/build_tarballs.jl helps here:

if [[ ${target} == x86_64-* ]] || [[ ${target} == i686-* ]]; then
    export CFLAGS="-O3 -mavx"
    export MAVX=-mavx
    FLAGS+=( --enable-avx2 )
fi

# if [[ "${target}" == x86_64-apple-darwin* ]]; then
#     # Work around the issue
#     #     /workspace/srcdir/SHOT/src/Model/../Model/Simplifications.h:1370:26: error: 'value' is unavailable: introduced in macOS 10.14
#     #                     optional.value()->coefficient *= -1.0;
#     #                              ^
#     #     /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/include/c++/v1/optional:947:27: note: 'value' has been explicitly marked unavailable here
#     #         constexpr value_type& value() &
#     #                               ^
#     export CXXFLAGS="-mmacosx-version-min=10.15"
#     # ...and install a newer SDK which supports `std::filesystem`
#     pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
#     rm -rf /opt/${target}/${target}/sys-root/System
#     cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
#     cp -ra System "/opt/${target}/${target}/sys-root/."
#     popd
# elif [[ "${target}" == aarch64-apple-darwin* ]]; then
#     # TODO: we need to fix this in the compiler wrappers
#     export CXXFLAGS="-mmacosx-version-min=11.0"
# elif [[ ${target} == *mingw* ]]; then
#     export LDFLAGS="-L${libdir}"
# fi

cmake -H. -B$prefix -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
cmake --build $prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
filter!(p -> !((arch(p) == "aarch64") |  (arch(p) == "armv6l")  |  (arch(p) == "armv7l") |  (arch(p) == "i686")), platforms)
#platforms = expand_cxxstring_abis(platforms)
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
    Dependency("boost_jll"; compat="=1.71.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
