# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TurboPFor"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/powturbo/TurboPFor-Integer-Compression.git", "43fb0b2abaef27f6753f4494ffff638c3002f24c"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TurboPFor-Integer-Compression

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/makefile.patch

make -j${nprocs} libic.${dlext}
mkdir -p ${libdir}
mv libic.${dlext} ${libdir}

install_license ${WORKSPACE}/srcdir/license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# platforms = [Platform("x86_64", "linux")]
platforms = [
     Platform("x86_64", "linux"; libc="glibc"),
     Platform("aarch64", "linux"; libc="glibc"),
     Platform("x86_64", "linux"; libc="musl"),
     Platform("aarch64", "linux"; libc="musl"),
     Platform("x86_64", "macos"),
     # Platform("x86_64", "freebsd"),
     Platform("x86_64", "windows"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libic", :libic)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
