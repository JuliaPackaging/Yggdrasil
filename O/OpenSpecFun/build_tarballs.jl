using BinaryBuilder

name = "OpenSpecFun"
version = v"0.5.3"

# Collection of sources required to build openspecfun
sources = [
    "https://github.com/JuliaMath/openspecfun/archive/v0.5.3.tar.gz" =>
    "1505c7a45f9f39ffe18be36f7a985cb427873948281dbcd376a11c2cd15e41e7",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd openspecfun-*/

# It needs to be told it's on Windows
if [[ ${target} == *mingw* ]]; then
    OS=WINNT
    libdir=$prefix/bin
elif [[ ${target} == *darwin* ]]; then
    OS=Darwin
fi

# Build it
make OS=${OS} CC="$CC" CXX="$CXX" FC="$FC" -j${nproc}

# Install it
make install OS=${OS} prefix=$prefix
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line. Since openspecfun uses
# Fortran for AMOS, we need the combinatorial explosion of platforms
# and GCC versions.
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libopenspecfun", :libopenspecfun)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
