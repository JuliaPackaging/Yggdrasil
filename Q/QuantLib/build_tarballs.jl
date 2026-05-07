# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QuantLib"
version = v"1.42.1"

sources = [
    GitSource("https://github.com/lballabio/QuantLib.git", "099987f0ca2c11c505dc4348cdb9ce01a598e1e5"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/QuantLib
install_license LICENSE.TXT
mkdir build
cd build

if [[ "${target}" == *86*-linux-gnu ]]; then
    # clock_gettime needs librt with the old glibc on x86 linux
    export LDFLAGS="-lrt"
fi

CMAKE_FLAGS=(
    -DCMAKE_INSTALL_PREFIX=${prefix}
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
    -DQL_EXTRA_SAFETY_CHECKS=ON
)

if [[ ${target} == *darwin* || ${target} == *freebsd* ]]; then
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS=-Wno-enum-constexpr-conversion)
fi

cmake "${CMAKE_FLAGS[@]}" -G Ninja ..
ninja -j${nproc}
ninja install
"""

# windows excluded b/c QL doesn't build with MinGW: https://github.com/JuliaPackaging/Yggdrasil/pull/7090#issuecomment-1646444669
platforms = expand_cxxstring_abis(supported_platforms(; exclude = Sys.iswindows))

products = [
    LibraryProduct("libQuantLib", :libQuantLib),
]

dependencies = [
    Dependency("boost_jll"; compat="=1.87.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6")
