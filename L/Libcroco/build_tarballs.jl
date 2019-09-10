# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libcroco"
version = v"0.6.13"

# Collection of sources required to build Libcroco
sources = [
    "https://download.gnome.org/sources/libcroco/$(version.major).$(version.minor)/libcroco-$(version).tar.xz" =>
    "767ec234ae7aa684695b3a735548224888132e063f92db585759b422570621d4"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libcroco-*/

if [[ "${target}" == *-apple-* ]]; then
    export EXTRA_OPTS="--disable-Bsymbolic"
    # Work around for
    #     size too large (archive member extends past the end of the file)
    # error.
    export RANLIB="/opt/${target}/bin/llvm-ranlib"
fi

./configure --prefix=$prefix --host=$target --disable-gtk-doc "${EXTRA_OPTS}"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcroco", :libcroco)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
    "XML2_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
