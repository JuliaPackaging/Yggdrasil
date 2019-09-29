# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Tcl"
version = v"8.6.9"

# Collection of sources required to build Tcl
sources = [
    "https://downloads.sourceforge.net/sourceforge/tcl/tcl$(version)-src.tar.gz" =>
    "ad0cd2de2c87b9ba8086b43957a0de3eb2eb565c7159d5f53ccbba3feb915f4e",
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/tcl*/win/
    # `make install` calls `tclsh` on Windows
    apk add tcl
else
    cd $WORKSPACE/srcdir/tcl*/unix/
fi

FLAGS=()
if [[ "${target}" == x86_64-* ]]; then
    FLAGS+=(--enable-64bit)
fi
./configure --prefix=${prefix} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libtcl8.6", "libtcl8", "tcl86"], :libtcl86),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
