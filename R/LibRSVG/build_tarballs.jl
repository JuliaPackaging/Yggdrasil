# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Librsvg"
version = v"2.42.2"

# Collection of sources required to build librsvg
sources = [
    "https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz" =>
    "0c550a0bffef768a436286116c03d9f6cd3f97f5021c13e7f093b550fac12562",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*/

# Pango's `.la` files are wrong on certain platforms, and we don't need them anyway
rm -f ${prefix}/lib/*.la

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/librsvg_link_order.patch"
autoreconf -f -i

# We need this for bootstrapping purposes
apk add gdk-pixbuf

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    # We purposefully use an old binutils, so we must disable -Bsymbolic
    FLAGS+=(--disable-Bsymbolic)
fi

# cssparser must be upgraded as it doesn't build properly anymore
sed -i.bak -e 's&cssparser = "0.23"&cssparser = "0.25"&' rust/Cargo.toml
(cd rust && cargo vendor)

LDFLAGS="-L${prefix}/lib -L${prefix}/lib64 -Wl,-rpath,${prefix}/lib -Wl,-rpath,${prefix}/lib64" ./configure --prefix=$prefix --host=$target \
    --disable-static \
    --enable-pixbuf-loader \
    --disable-introspection \
    --disable-gtk-doc-html \
    --enable-shared \
    "${FLAGS[@]}"

if [[ ${target} == *mingw* ]]; then
    # pass static rust package to linker
    sed -i "s/^deplibs_check_method=.*/deplibs_check_method=\"pass_all\"/g" libtool
    # add missing crt libs (ws2_32 and userenv) to LIBRSVG_LIBS
    sed -i "s/^LIBRSVG_LIBS = .*/& -lws2_32 -luserenv/g" Makefile
fi

# Don't try to unwind on i686-w64-mingw32, just panic because rust doesn't know how to SLJL
# https://github.com/rust-lang/rust/issues/12859#issuecomment-185081071
if [[ ${target} == i686-w64-mingw32 ]]; then
    export RUSTFLAGS="-C panic=abort"
fi

# Manually build rust library because rust target doesn't match C target
(cd rust && PKG_CONFIG_ALLOW_CROSS=1 cargo build --release)

RUST_LIB="$(pwd)/rust/target/${rust_target}/release/librsvg_internals.a"
if [[ ${target} == *mingw32* ]]; then
    mv "$(pwd)/rust/target/${rust_target}/release/rsvg_internals.lib" "${RUST_LIB}"
fi

make RUST_LIB="${RUST_LIB}" -j${nproc}
make RUST_LIB="${RUST_LIB}" install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    # The main event
    LibraryProduct("librsvg-2", :librsvg),

    # This is named `.so` even on darwin, so do it as a FileProduct.....sigh
    FileProduct(["lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so",
                 "lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.dll"], :libpixbufloader_svg),
    #LibraryProduct("libpixbufloader-svg", :libpixbufloader_svg, ["lib/gdk-pixbuf-2.0/2.10.0/loaders"]),

    # And to round it out, let's get an executable as well!
    ExecutableProduct("rsvg-convert", :rsvg_convert),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "gdk_pixbuf_jll",
    "Pango_jll",
    "Libcroco_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :rust])
