# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"
version = v"2.11.3"

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "6bc96bf65053c8664722b40f1d416aed9532c76c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/c-blosc2/

# Blosc2 mis-detects whether the system headers provide `_xsetbv`
# (probably on several platforms), and on `x86_64-w64-mingw32` the
# functions have incompatible return types (although both are 64-bit
# integers).
atomic_patch -p1 ../patches/_xsetbv.patch

# Clang on Apple does not (yet?) properly support `__builtin_cpu_supports`.
# The symbol `__cpu_model` is not provided by any standard library.
if [[ "${target}" == x86_64-apple-darwin* ]]; then
    perl -pi -e 's/#define HAVE_CPU_FEAT_INTRIN/#undef HAVE_CPU_FEAT_INTRIN/' blosc/shuffle.c
fi

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_STATIC=OFF \
    -DPREFER_EXTERNAL_ZLIB=ON \
    -DPREFER_EXTERNAL_ZSTD=ON \
    -DPREFER_EXTERNAL_LZ4=ON \
    ..
make -j${nproc}
make install
install_license ../LICENSES/*.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"; compat="1.5.0"),
    Dependency("Lz4_jll"; compat="1.9.3"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 for powerpc.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
