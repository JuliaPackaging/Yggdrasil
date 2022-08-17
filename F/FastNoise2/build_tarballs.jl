# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastNoise2"
version = v"0.9.4"

# Collection of sources required to complete build
sources = [
    "https://github.com/Auburn/FastNoise2/archive/refs/tags/v$version-alpha.tar.gz" => "e1bf4a2ea7d36efff0ae5b471c6311088f5fa5ab40a52021a79dda2563bdaa42",
]

# Bash recipe for building across all platforms
script = raw"""
mv FastNoise2-* FastNoise2

cd FastNoise2
cmake -S . -B build -D FASTNOISE2_NOISETOOL=OFF -D FASTNOISE2_TESTS=OFF -D BUILD_SHARED_LIBS=ON -D CMAKE_FIND_ROOT_PATH=${prefix} -D CMAKE_INSTALL_PREFIX=${prefix} -D CMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}

cd build
make -j ${nprocs}
make install
install_license ${WORKSPACE}/srcdir/FastNoise2/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libFastNoise", :libFastNoise),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"9",
    julia_compat="1.6",
    allow_unsafe_flags=true
)
