# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "Cairo"
version = v"1.16.0"

sources = [
    "https://www.cairographics.org/releases/cairo-$(version).tar.xz" =>
    "5e7b29b3f113ef870d1e3ecf8adf21f923396401604bda16d44be45e66052331",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairo-*/

# Because `zlib` doesn't have a proper `.pc` file, configure fails to find.
export CPPFLAGS="-I${prefix}/include"

if [[ "${target}" == *-apple-* ]]; then
    BACKEND_OPTIONS="--enable-quartz --enable-quartz-image --disable-xcb --disable-xlib"
elif [[ "${target}" == *-mingw* ]]; then
    BACKEND_OPTIONS="--enable-win32 --disable-xcb --disable-xlib"
elif [[ "${target}" == *-linux-* ]] || [[ "${target}" == *freebsd* ]]; then
    BACKEND_OPTIONS="--enable-xlib --enable-xcb --enable-xlib-xcb"
fi

./configure --prefix=${prefix} --host=${target} \
    --disable-static \
    --enable-ft \
    --enable-tee \
    --enable-svg \
    --enable-ps \
    --enable-pdf \
    --enable-gobject \
    --disable-dependency-tracking \
    ${BACKEND_OPTIONS}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcairo", :libcairo),
    LibraryProduct("libcairo-gobject", :libcairo_gobject),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Glib_jll",
    "Pixman_jll",
    "libpng_jll",
    "Fontconfig_jll",
    "FreeType2_jll",
    "Bzip2_jll",
    "Xorg_libXext_jll",
    "Xorg_libXrender_jll",
    "LZO_jll",
    "Zlib_jll",
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
