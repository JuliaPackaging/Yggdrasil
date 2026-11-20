# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "MiniZinc"

version = v"2.11.0"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "aac81d56847356090a4d915576e8719d196a1395",
    ),
    # libminizinc fetches these with CMake FetchContent at configure time. The
    # tags must match the versions in cmake/targets/libminizinc_parser.cmake and
    # cmake/targets/libmzn.cmake.
    GitSource(
        "https://github.com/tree-sitter/tree-sitter.git",
        "808e4b1fc06e269a107c4bd8bd936cc6fde18b00";
        tag="v0.26.12",
    ),
    GitSource(
        "https://github.com/Dekker1/tree-feller.git",
        "d7fbfcf156cbb4568989841a3dee7090b3028139";
        tag="v0.1.1",
    ),
    GitSource(
        "https://github.com/microsoft/mimalloc.git",
        "d4881d338125e1cb7c47ba4cfb398d6f7c0c8d45";
        tag="v3.5.3",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

CMAKE_FLAGS=(
    # Use the sources downloaded above instead of fetching them during the build.
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON
    -DFETCHCONTENT_SOURCE_DIR_TREE-SITTER=${WORKSPACE}/srcdir/tree-sitter
    -DFETCHCONTENT_SOURCE_DIR_TREE_FELLER=${WORKSPACE}/srcdir/tree-feller
    -DFETCHCONTENT_SOURCE_DIR_MIMALLOC=${WORKSPACE}/srcdir/mimalloc
    # mimalloc adds -march=armv8.1-a by default on arm64, which BinaryBuilder forbids.
    -DMI_OPT_ARCH=OFF
    # libmzn is dlopen'ed into Julia, so mimalloc must not replace the
    # process-wide malloc (it segfaults on load). MiniZinc still uses mimalloc
    # for its own AST allocations.
    -DMZN_MIMALLOC_OVERRIDE=OFF
)
if [[ "${target}" == *-mingw* ]]; then
    # The tree-sitter grammars mark two symbols __declspec(dllexport), which
    # disables MinGW's automatic export of every other symbol in libmzn.
    CMAKE_FLAGS+=(-DCMAKE_SHARED_LINKER_FLAGS="-Wl,--export-all-symbols")
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    "${CMAKE_FLAGS[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE.txt
"""

# std::filesystem needs the macOS 10.15 SDK on x86_64-apple-darwin.
sources, script = require_macos_sdk("10.15", sources, script)

products = [
    ExecutableProduct("minizinc", :minizinc),
    LibraryProduct("libmzn", :libmzn),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(os(p) == "freebsd"), platforms)
filter!(p -> !(arch(p) == "i686" && Sys.iswindows(p)), platforms)
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # Use an exact version for HiGHS. @odow has observed segfaults with
    # HiGHS_jll v1.5.3 when libminizinc compiled with v1.5.1.
    Dependency("HiGHS_jll"; compat="=1.16.0"),
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
    preferred_gcc_version = v"12",
    julia_compat = "1.10",
)
