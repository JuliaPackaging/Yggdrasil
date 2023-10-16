# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Blosc2"
version = v"2.10.5"

# Collection of sources required to build Blosc2
sources = [
    GitSource("https://github.com/Blosc/c-blosc2.git", "f8417b103e6b0bbe06b861f92d57285590e1166a"),
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

# fix compile arguments for armv7l <https://github.com/Blosc/c-blosc2/pull/563>
atomic_patch -p1 ../patches/armv7l.patch

mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_STATIC=OFF \
    -DCMAKE_SHARED_LIBRARY_LINK_C_FLAGS="" \
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
platforms = supported_platforms(; experimental=true)

# Blosc2 requires NEON on ARM platforms; see <https://github.com/Blosc/c-blosc2/issues/465>
platforms = filter(p -> arch(p) ≠ "armv7l", platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libblosc2", :libblosc2),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
    Dependency("Lz4_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 for powerpc.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
