# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.7.6"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "3eacc4cd3e6ba1b5414e9fa1639beaefa270f24b",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch

# Patch for MinGW toolchain
find .. -type f -exec sed -i 's/Windows.h/windows.h/g' {} +

mkdir -p build
cd build

# FAST_BUILD is needed when linking HiGHS, because that's what
# we used when compiling HiGHS_jll.
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-I${includedir}/highs" \
    -DFAST_BUILD=ON \
    ..

if [[ "${target}" == *-linux-* ]]; then
        make -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build . --config Release
    else
        cmake --build . --config Release --parallel
    fi
fi
make install
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
    Dependency("HiGHS_jll"; compat="=1.6.0"),
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
