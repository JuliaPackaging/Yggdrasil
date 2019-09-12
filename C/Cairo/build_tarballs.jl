# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
name = "Cairo"
version = v"1.14.12"

sources = [
    "https://www.cairographics.org/releases/cairo-$(version).tar.xz" =>
    "8c90f00c500b2299c0a323dd9beead2a00353752b2092ead558139bd67f7bf16",
    "./bundled"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/cairo-*/

export LDFLAGS="${LDFLAGS} -L${libdir}"
# TODO: find out why we need to manually add "${prefix}/include/freetype2",
# the pkg-config file for freetype2 should already have this information.
export CPPFLAGS="-I${prefix}/include -I${prefix}/include/freetype2"

if [[ "${target}" == *-apple-* ]]; then
    BACKEND_OPTIONS="--enable-quartz --enable-quartz-image --disable-xcb --disable-xlib"
elif [[ "${target}" == *-mingw* ]]; then
    BACKEND_OPTIONS="--enable-win32 --disable-xcb --disable-xlib"
elif [[ "${target}" == *-linux-* ]] || [[ "${target}" == *freebsd* ]]; then
    BACKEND_OPTIONS="--enable-xlib --enable-xcb --enable-xlib-xcb"
fi

# There is a mess with the version of freetype2.  The following patch changes
# the required version to the one that is actually found by pkg-config.
atomic_patch -p1 ../patches/configure.ac.patch
./autogen.sh --prefix=${prefix} --host=${target}
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
