# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Readline"
version = v"8.3.3"
version_str = "$(version.major).$(version.minor)"
version_str2 = "$(version.major)$(version.minor)"

# Collection of sources required to build Readline
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version_str).tar.gz",
                  "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc"),
    FileSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version_str)/readline83-001",
               "21f0a03106dbe697337cd25c70eb0edbaa2bdb6d595b45f83285cdd35bac84de"),
    FileSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version_str)/readline83-002",
               "e27364396ba9f6debf7cbaaf1a669e2b2854241ae07f7eca74ca8a8ba0c97472"),
    FileSource("https://ftpmirror.gnu.org/gnu/readline/readline-$(version_str)/readline83-003",
               "72dee13601ce38f6746eb15239999a7c56f8e1ff5eb1ec8153a1f213e4acdb29"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/readline-*/

atomic_patch -p0 ${WORKSPACE}/srcdir/readline83-001
atomic_patch -p0 ${WORKSPACE}/srcdir/readline83-002
atomic_patch -p0 ${WORKSPACE}/srcdir/readline83-003

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
