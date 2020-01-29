# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastJet"
version = v"3.3.3.2"

# Collection of sources required to complete build
sources = [
    "http://fastjet.fr/repo/fastjet-$(version).tar.gz" =>
    "30b0a0282ce5aeac9e45862314f5966f0be941ce118a83ee4805d39b827d732b",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fastjet-*/
export CXXFLAGS="-O3 -Wall"
export CFLAGS="-O3 -Wall"
if [[ "${target}" == *-freebsd* ]]; then
    # Needed to fix the following errors
    #   undefined reference to `backtrace_symbols'
    #   undefined reference to `backtrace'
    export LDFLAGS="-lexecinfo"
fi
FLAGS=()
if [[ "${target}" == *-mingw* ]]; then
    # This is needed in order to build the shared library on Windows when we get
    #   libtool: warning: undefined symbols not allowed in x86_64-w64-mingw32 shared libraries; building static only
    FLAGS+=(LDFLAGS="-no-undefined")
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-auto-ptr
make -j ${nprocs} "${FLAGS[@]}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc),
    Linux(:x86_64, libc=:musl),
    MacOS(:x86_64),
    Windows(:x86_64)
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
