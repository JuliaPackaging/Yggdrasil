# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mesa"
version = v"20.1.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://archive.mesa3d.org/mesa-$version.tar.xz", "fac1861e6e0bf1aec893f8d86dbfb9d8a0f426ff06b05256df10e3ad7e02c69b"),
]

# Bash recipe for building across all platforms
script = raw"""
mkdir build
cd build
apk add py3-mako
meson -D b_ndebug=true -D buildtype=release -D strip=true -D llvm=false ../mesa* --cross-file="${MESON_TARGET_TOOLCHAIN}"
ninja -j${nproc}
ninja install
mv $prefix/bin/opengl32.dll $prefix/bin/opengl32sw.dll
install_license ../mesa*/docs/license.html
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "windows"),
    Platform("i686", "windows")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("opengl32sw", :opengl32sw; dont_dlopen=true)
]

# Dependencies that must be installed before this package can be built
dependencies = [
  Dependency("Zlib_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
