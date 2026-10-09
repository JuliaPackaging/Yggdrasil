# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.10.1"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "c3448c48e7f05f13805616cfd1b9e94972eef58c",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/01-file_utils-use-_WIN32-guards.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/02-file_utils-cxx11-lambda.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/03-process-qualify-std-thread.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/04-FILE_PATH-libstdcxx-wchar.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/05-mingw-municode-wmain.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/06-highs-plugin-libhighs-dll.patch

# Patch for MinGW toolchain
find .. -type f -exec sed -i 's/Windows.h/windows.h/g' {} +

CMAKE_FLAGS=()
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
platforms = supported_platforms(;
    exclude = p -> Sys.isbsd(p) || (arch(p) == "i686" && Sys.iswindows(p)),
)
platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # Use an exact version for HiGHS. @odow has observed segfaults with
    # HiGHS_jll v1.5.3 when libminizinc compiled with v1.5.1.
    Dependency("HiGHS_jll"; compat="=1.15.1"),
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
