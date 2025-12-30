# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.9.3"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "a3297cbe6716e0e544a667eb2e5cfde3b151a855",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch

# Patch for MinGW toolchain
find .. -type f -exec sed -i 's/Windows.h/windows.h/g' {} +

# FAST_BUILD is needed when linking HiGHS, because that's what
# we used when compiling HiGHS_jll.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-I${includedir}/highs" \
    -DFAST_BUILD=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

products = [
    ExecutableProduct("minizinc", :minizinc),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(
    supported_platforms(; exclude = p -> arch(p) == "i686" && Sys.iswindows(p)),
)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # Use an exact version for HiGHS. @odow has observed segfaults with
    # HiGHS_jll v1.5.3 when libminizinc compiled with v1.5.1.
    Dependency("HiGHS_jll"; compat="=1.11.0"),
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
    preferred_gcc_version = v"6",
    julia_compat = "1.6",
)
