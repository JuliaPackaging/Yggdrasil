# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LetsBeRational"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tbeason/letsberational.git", "0c84bc23347a10272d6bd0e1e01344b41bb506cc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/letsberational
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libletsberational", :libletsberational)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

