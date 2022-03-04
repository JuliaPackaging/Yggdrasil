# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Librsvg"
version = v"2.52.4"

# Collection of sources required to build librsvg
sources = [
    ArchiveSource("https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz",
                  "660ec8836a3a91587bc9384920132d4c38d1d1718c67fe160c5213fe4dec2928"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*/

atomic_patch -p1 ../patches/0001-Makefile.am-use-the-correct-EXEEXT-extension-for-the.patch
autoreconf -fiv

# On most platforms we have to use `${rust_target}` as `host`
FLAGS=(--host=${rust_target})
if [[ "${target}" == *-mingw* ]]; then
    # On Windows using `${rust_target}` wouldn't work:
    #
    #     Invalid configuration `x86_64-pc-windows-gnu': Kernel `windows' not known to work with OS `gnu'.
    #
    # Then we have to use `RUST_TARGET` to set the Rust target.  I haven't found
    # a combination host and RUST_TARGET that would work on all platforms.  If
    # you do, let me know!
    FLAGS=(--host=${target} RUST_TARGET="${rust_target}" LIBS="-luserenv -lbcrypt")
fi

./configure \
    --build=${MACHTYPE} \
    --prefix=${prefix} \
    --disable-static \
    --enable-pixbuf-loader \
    --disable-introspection \
    --disable-gtk-doc-html \
    --enable-shared \
    "${FLAGS[@]}"
make
make install
install_license COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# We dont have all dependencies for armv6l
filter!(p -> arch(p) != "armv6l", platforms)
# Rust toolchain for i686 Windows is unusable
filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

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
    # We need to run `gdk-pixbuf-query-loaders`
    HostBuildDependency("gdk_pixbuf_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    Dependency("gdk_pixbuf_jll"),
    Dependency("Pango_jll"; compat="1.47.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:c, :rust])
