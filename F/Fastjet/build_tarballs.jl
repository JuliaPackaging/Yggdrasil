# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Fastjet"
version = v"3.3.3"

# Collection of sources required to complete build
sources = [
    "http://fastjet.fr/repo/fastjet-3.3.3.tar.gz" =>
    "30b0a0282ce5aeac9e45862314f5966f0be941ce118a83ee4805d39b827d732b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd fastjet-3.3.3/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j ${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:musl),
    Linux(:x86_64, libc=:glibc),
    MacOS(:x86_64)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsiscone", :libsiscone),
    LibraryProduct("libfastjetplugins", :libfastjetplugins),
    LibraryProduct("libfastjettools", :libfastjettools),
    LibraryProduct("libsiscone_spherical", :libsiscone_spherical),
    LibraryProduct("libfastjet", :libfastjet)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

