# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

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
    # Force shared library on all platforms. On UNIX this matches the upstream
    # default (BUILD_SHARED_LIBS=${UNIX}); on MinGW it overrides the static-only
    # default so we ship a DLL.
    -DBUILD_SHARED_LIBS=ON
    # Auto-generate the symbol export list on Windows (no-op elsewhere) so the
    # MinGW DLL has its symbols visible; QuantLib doesn't use __declspec(dllexport).
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
)

CXX_EXTRA_FLAGS=""
if [[ ${target} == *darwin* || ${target} == *freebsd* ]]; then
    # Boost violates the C++17 enum-to-int constexpr rule; Yggdrasil's
    # Clang treats this as a hard error.
    CXX_EXTRA_FLAGS="-Wno-enum-constexpr-conversion"
fi
if [[ ${target} == *darwin* ]]; then
    # Workaround upstream QuantLib bug: ql/termstructures/volatility/
    # equityfx/blackvoltimeextrapolation.cpp uses std::vector without
    # an #include <vector>. libc++ on darwin doesn't pull it in
    # transitively (libstdc++ on Linux does).
    CXX_EXTRA_FLAGS="${CXX_EXTRA_FLAGS} -include vector"
fi
if [[ ${target} == *mingw* ]]; then
    # boost_jll ships shared Boost on MinGW; tell Boost headers to mark
    # symbols as dllimport instead of expecting static linkage.
    CXX_EXTRA_FLAGS="${CXX_EXTRA_FLAGS} -DBOOST_ALL_DYN_LINK"
fi
if [ -n "${CXX_EXTRA_FLAGS}" ]; then
    CMAKE_FLAGS+=(-DCMAKE_CXX_FLAGS="${CXX_EXTRA_FLAGS}")
fi

cmake "${CMAKE_FLAGS[@]}" -G Ninja ..
ninja -j${nproc}
ninja install
"""

# Install a newer macOS SDK so std::any_cast (introduced in 10.14) is available;
# QuantLib uses it in ql/instrument.hpp.
sources, script = require_macos_sdk("10.15", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libQuantLib", :libQuantLib),
]

dependencies = [
    Dependency("boost_jll"; compat="=1.87.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"9", julia_compat="1.6")
