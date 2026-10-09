# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FindMUS"
version = v"2.10.1"

sources = [
    GitSource(
        "https://github.com/minizinc/FindMUS.git",
        "5ee1c89028fab9cbc4ae426c06a2f58869a24f60",
    ),
]

# find_package(libminizinc) resolves against MiniZinc_jll's
# lib/cmake/libminizinc config (shipped alongside lib/libmzn.a and
# include/minizinc/).
#
# findMUS's own targets include the vendored MiniSat's Options.h, which uses
# PRIi64 and INT64_MIN/INT64_MAX. MiniSat's CMakeLists defines
# __STDC_FORMAT_MACROS / __STDC_LIMIT_MACROS, but only in its subdirectory
# scope, so findMUS's sources fail to compile against the older-glibc and musl
# <inttypes.h>/<stdint.h>. Define both globally via CMAKE_CXX_FLAGS.
script = raw"""
cd $WORKSPACE/srcdir/FindMUS
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix};${prefix}/CMake" \
    -DCMAKE_CXX_FLAGS="-D__STDC_FORMAT_MACROS -D__STDC_LIMIT_MACROS"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.txt
"""

products = [
    ExecutableProduct("findMUS", :findMUS),
    FileProduct("share/minizinc/solvers/findmus.msc", :findmus_msc),
]

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # findMUS links MiniZinc_jll's libmzn.a, so this is an exact pin that must
    # move in lockstep with the MiniZinc_jll version.
    Dependency("MiniZinc_jll"; compat = "=2.10.1"),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"12",  # matches MiniZinc_jll for ABI compatibility
    julia_compat = "1.10",
)
