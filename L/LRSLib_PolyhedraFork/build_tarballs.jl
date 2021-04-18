# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LRS_PolyhedraFork"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JuliaPolyhedra/lrslib.git", "d8b723a2c315614979a8354f9e768d273d14a215"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd lrslib
install_license COPYING

if [ $(uname) = "Darwin" ]; then
    atomic_patch -p1 ../makefile.osx.patch
fi

make liblrs.${dlext}.0 SONAME=liblrs.${dlext} SHLIB=liblrs.${dlext}.0
cp liblrs.${dlext}.0 ${libdir}/liblrs.${dlext}

cp ../makefile.liblrsnash .
make -f makefile.liblrsnash SHLIB=liblrsnash.${dlext} LIBLRSDIR=${libdir}
cp liblrsnash.${dlext} ${libdir}/liblrsnash.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("liblrsnash", :liblrsnash),
    LibraryProduct("liblrs", :liblrs)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GMP_jll", uuid="781609d7-10c4-51f6-84f2-b8444358ff6d"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
