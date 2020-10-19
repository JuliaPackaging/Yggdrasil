# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Ncurses"
version = v"6.1"

# Collection of sources required to build Ncurses
sources = [
    ArchiveSource("https://ftp.gnu.org/pub/gnu/ncurses/ncurses-$(version.major).$(version.minor).tar.gz",
                  "aa057eeeb4a14d470101eff4597d5833dcef5965331be3528c08d99cebaa0d17"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ncurses-*/

# We need to run the native "tic" program
apk add ncurses

CONFIG_FLAGS=""
if [[ ${target} == x86_64-apple-darwin14 ]]; then
    CONFIG_FLAGS="${CONFIG_FLAGS} --disable-stripping"
elif [[ "${target}" == *-mingw* ]]; then
    CONFIG_FLAGS="--enable-sp-funcs --enable-term-driver"
    export CFLAGS="-lintl -liconv"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-shared \
    --disable-static \
    --without-manpages \
    --with-normal \
    --without-debug \
    --without-ada \
    --without-cxx-binding \
    --enable-widec \
    --enable-pc-files \
    --disable-rpath \
    --enable-colorfgbg \
    --enable-ext-colors \
    --enable-ext-mouse \
    --enable-warnings \
    --enable-assertions \
    --enable-database \
    ${CONFIG_FLAGS}
make -j${nproc}
make install

# Remove duplicates that don't work on case-insensitive filesystems
rm -f  ${prefix}/share/terminfo/2/2621a
rm -rf ${prefix}/share/terminfo/a
rm -rf ${prefix}/share/terminfo/e
rm -f  ${prefix}/share/terminfo/h/hp2621a
rm -f  ${prefix}/share/terminfo/h/hp70092a
rm -rf ${prefix}/share/terminfo/l
rm -rf ${prefix}/share/terminfo/m
rm -rf ${prefix}/share/terminfo/n
rm -rf ${prefix}/share/terminfo/p
rm -rf ${prefix}/share/terminfo/q
rm -rf ${prefix}/share/terminfo/X

# Install pc files and fool packages looking for non-wide-character ncurses
for lib in ncurses form panel menu; do
    if [[ "${target}" == *-mingw* ]]; then
        # O Windows, Windows, wherefore art thou Windows?
        abiver=6
    fi
    install -Dm644 "misc/${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}w.pc"
    ln -s "${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}.pc"
    ln -s "lib${lib}w${abiver}.${dlext}" "${libdir}/lib${lib}${abiver}.${dlext}"
done
ln -s ncursesw ${prefix}/include/ncurses
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
    LibraryProduct(["libform", "libform6"], :libform),
    LibraryProduct(["libmenu", "libmenu6"], :libmenu),
    LibraryProduct(["libncurses", "libncurses6"], :libncurses),
    LibraryProduct(["libpanel", "libpanel6"], :libpanel),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Gettext_jll"),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

