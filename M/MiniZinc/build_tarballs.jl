# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.11.0"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "aac81d56847356090a4d915576e8719d196a1395",
    ),
    # libminizinc fetches these with CMake FetchContent at configure time. The
    # versions and hashes must match cmake/targets/libminizinc_parser.cmake and
    # cmake/targets/libmzn.cmake.
    ArchiveSource(
        "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.12.tar.gz",
        "428e2b182fe38eddc100d8bd851e47c96921a69281b66abafc25ba4b0aaeeeab",
    ),
    ArchiveSource(
        "https://github.com/Dekker1/tree-feller/archive/refs/tags/v0.1.1.tar.gz",
        "4a6b463da95ec6a9a1014732df6e77dabdb5e20c95cd9005107d1d4596e92cf9",
    ),
    ArchiveSource(
        "https://github.com/microsoft/mimalloc/archive/refs/tags/v3.5.3.tar.gz",
        "3b4a15153a59905995f7070296ed604bb5ccc00cabb8b93446931aff77224d47",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

CMAKE_FLAGS=(
    # Use the sources downloaded above instead of fetching them during the build.
    -DFETCHCONTENT_FULLY_DISCONNECTED=ON
    -DFETCHCONTENT_SOURCE_DIR_TREE-SITTER=${WORKSPACE}/srcdir/tree-sitter-0.26.12
    -DFETCHCONTENT_SOURCE_DIR_TREE_FELLER=${WORKSPACE}/srcdir/tree-feller-0.1.1
    -DFETCHCONTENT_SOURCE_DIR_MIMALLOC=${WORKSPACE}/srcdir/mimalloc-3.5.3
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
"""

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
