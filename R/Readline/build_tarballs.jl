# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Readline"
version = v"8.0"

# Collection of sources required to build Readline
sources = [
    "https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor).tar.gz" =>
    "e339f51971478d369f8a053a330a190781acb9864cf4c541060f12078948e461",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/readline-*/

export CPPFLAGS="-I${prefix}/include"
if [[ "${target}" == *-mingw* ]]; then
    # Only on Windows the library name embeds the ABI version
    export NCURSES_ABI_VER=6
    export LDFLAGS="-L${libdir}"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses
make -j${nproc} SHLIB_LIBS="-lncurses${NCURSES_ABI_VER}"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libhistory", "libhistory8"], :libhistory),
    LibraryProduct(["libreadline", "libreadline8"], :libreadline),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Ncurses_jll",
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
