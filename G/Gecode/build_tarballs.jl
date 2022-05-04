# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Gecode"

version = v"6.2.0"

sources = [
    GitSource(
        "https://github.com/Gecode/gecode.git",
        "2925392ac7a0c8a7b33aaee51721d84725605919",
    ),
]

script = raw"""
cd $WORKSPACE/srcdir/gecode

mkdir -p build
cd build

if [[ "${target}" == *mingw* ]]; then
    export LDFLAGS="${LDFLAGS} -lws2_32"
fi

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
    ExecutableProduct("fzn-gecode", :fzngecode),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

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
