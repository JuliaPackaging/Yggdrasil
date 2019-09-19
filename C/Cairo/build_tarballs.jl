# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "Cairo"
version = v"1.14.12"

sources = [
    "https://www.cairographics.org/releases/cairo-$(version).tar.xz" =>
    "8c90f00c500b2299c0a323dd9beead2a00353752b2092ead558139bd67f7bf16",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairo-*/

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
    "X11_jll",
    "LZO_jll",
    "Zlib_jll",
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
