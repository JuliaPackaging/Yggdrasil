# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Readline"
version = v"8.1.1"

# Collection of sources required to build Readline
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor).tar.gz",
                  "f8ceb4ee131e3232226a17f51b164afc46cd0b9e6cef344be87c65962cb82b02"),
    FileSource("https://ftp.gnu.org/gnu/readline/readline-$(version.major).$(version.minor)-patches/readline81-001",
               "682a465a68633650565c43d59f0b8cdf149c13a874682d3c20cb4af6709b9144"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/readline-*/

atomic_patch -p0 ${WORKSPACE}/srcdir/readline81-001
# Patch from https://aur.archlinux.org/cgit/aur.git/tree/fix_signal.diff?h=mingw-w64-readline
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-fix_signal.patch

export CPPFLAGS="-I${includedir}"
if [[ "${target}" == *-mingw* ]]; then
    # Only on Windows the library name embeds the ABI version
    export NCURSES_ABI_VER=6
fi
if [[ "${target}" == *-mingw* ]] || [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-L${libdir}"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --with-curses
make -j${nproc} SHLIB_LIBS="-lncurses${NCURSES_ABI_VER}"
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libhistory", "libhistory8"], :libhistory),
    LibraryProduct(["libreadline", "libreadline8"], :libreadline),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Ncurses_jll"),
]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
