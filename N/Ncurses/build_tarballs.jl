# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg.BinaryPlatforms

name = "Ncurses"
version = v"6.1"

# Collection of sources required to build Ncurses
sources = [
    "https://ftp.gnu.org/pub/gnu/ncurses/ncurses-$(version.major).$(version.minor).tar.gz" =>
    "aa057eeeb4a14d470101eff4597d5833dcef5965331be3528c08d99cebaa0d17",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ncurses-*/

# We need to run the native "tic" program
apk add ncurses

CONFIG_FLAGS=""
if [[ ${target} == x86_64-apple-darwin14 ]]; then
    CONFIG_FLAGS="${CONFIG_FLAGS} --disable-stripping"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-shared \
    --with-normal \
    --without-debug \
    --without-ada \
    --without-cxx-binding \
    --enable-widec \
    --enable-pc-files \
    ${CONFIG_FLAGS}
make -j${nproc}
make install

# Install pc files and fool packages looking for non-wide-character ncurses
for lib in ncurses form panel menu; do
    install -Dm644 "misc/${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}w.pc"
    ln -s "${lib}w.pc" "${prefix}/lib/pkgconfig/${lib}.pc"
    ln -s "lib${lib}w.${dlext}" "${libdir}/lib${lib}.${dlext}"
done
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if !(p isa Windows)]

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libform", :libform),
    LibraryProduct("libmenu", :libmenu),
    LibraryProduct("libncurses", :libncurses),
    LibraryProduct("libpanel", :libpanel),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
