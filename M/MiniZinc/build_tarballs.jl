# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "MiniZinc"

version = v"2.6.3"

sources = [
    GitSource(
        "https://github.com/MiniZinc/libminizinc.git",
        "b81f14ac41bc6f6ec6cfe7ede408c9f3447a6a76",
    ),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/libminizinc

# Patches for MinGW toolchain, but we're not building that yet.
# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fixes.patch
# find .. -type f -exec sed -i 's/Windows.h/windows.h/g' {} +

mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    ..

if [[ "${target}" == *-linux-* ]]; then
        make -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build . --config RelWithDebInfo
    else
        cmake --build . --config RelWithDebInfo --parallel
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

dependencies = []

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
