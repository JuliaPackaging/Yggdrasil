# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "YAJL"
version = v"2.1.1"

# Collection of sources required to build YAJL
sources = [
    GitSource("https://github.com/lloyd/yajl.git",
              "a0ecdde0c042b9256170f2f8890dd9451a4240aa"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd yajl

if [[ "$target" == *-w64-* ]]; then
  atomic_patch -p1 "$WORKSPACE/srcdir/patches/01-fix-windows-compiler.patch"
fi

mkdir build
cd build

cmake \
  -DCMAKE_INSTALL_PREFIX="$prefix" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE="Release" \
  ..

make "-j$nproc"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libyajl", :libyajl),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
