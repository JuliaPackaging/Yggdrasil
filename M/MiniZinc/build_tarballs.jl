# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.7.4"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "834c8c1da9816322d4dcad52ae067fbf584ac6b9",
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

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
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
platforms = expand_cxxstring_abis(supported_platforms())

# TODO(odow): fix build issues on Windows
platforms = filter(!Sys.iswindows, platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
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
