# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Readline"
version = v"8.0.4"

# Collection of sources required to build Readline
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor).tar.gz",
                  "e339f51971478d369f8a053a330a190781acb9864cf4c541060f12078948e461"),
    FileSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline80-001",
               "d8e5e98933cf5756f862243c0601cb69d3667bb33f2c7b751fe4e40b2c3fd069"),
    FileSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline80-002",
               "36b0febff1e560091ae7476026921f31b6d1dd4c918dcb7b741aa2dad1aec8f7"),
    FileSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline80-003",
               "94ddb2210b71eb5389c7756865d60e343666dfb722c85892f8226b26bb3eeaef"),
    FileSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline80-004",
               "b1aa3d2a40eee2dea9708229740742e649c32bb8db13535ea78f8ac15377394c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/readline-*/

atomic_patch -p0 ${WORKSPACE}/srcdir/readline80-001
atomic_patch -p0 ${WORKSPACE}/srcdir/readline80-002
atomic_patch -p0 ${WORKSPACE}/srcdir/readline80-003
atomic_patch -p0 ${WORKSPACE}/srcdir/readline80-004

export CPPFLAGS="-I${prefix}/include"
if [[ "${target}" == *-mingw* ]]; then
    # Only on Windows the library name embeds the ABI version
    export NCURSES_ABI_VER=6
    export LDFLAGS="-L${libdir}"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses
make -j${nproc} SHLIB_LIBS="-lncurses${NCURSES_ABI_VER}"
make install
install_license COPYING
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

