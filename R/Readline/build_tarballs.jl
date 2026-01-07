# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Readline"
version_str = "8.3"
version = VersionNumber(version_str)

# Collection of sources required to build Readline
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version_str).tar.gz",
                  "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/readline-*/

# Declare `struct winsize` on Windows. We'll never actually use it.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-winsize.patch

export CPPFLAGS="-I${includedir}"
if [[ "${target}" == *-mingw* ]]; then
    # Only on Windows the library name embeds the ABI version
    export NCURSES_ABI_VER=6
fi
if [[ "${target}" == *-mingw* ]] || [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-L${libdir}"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --target=${target} --with-curses
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
    Dependency("Ncurses_jll"; compat="6.5.1"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
