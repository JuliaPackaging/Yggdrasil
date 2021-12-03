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

# Our Musl toolchain is missing a symlink `libc.musl-${musl_arch}.so.1` -> `libc.so`, let's
# create it manually until we fix it directly in the compiler shards.
if [[ "${target}" == *-linux-musl* ]]; then
    case "${target}" in
        i686*)
            musl_arch="i386" ;;
        arm*)
            musl_arch="armhf" ;;
        *)
            musl_arch="${target%%-*}" ;;
    esac
    # If this errors out because `libc.musl-${musl_arch}.so.1` already exists it'll mean we
    # can remove this hack.
    ln -sv libc.so /opt/${target}/${target}/sys-root/usr/lib/libc.musl-${musl_arch}.so.1
fi

./configure --host=${rust_target} \
    --build=${MACHTYPE} \
    --prefix=${prefix} \
    --disable-static \
    --enable-pixbuf-loader \
    --disable-introspection \
    --disable-gtk-doc-html \
    --enable-shared
make
make install
install_license COPYING.LIB
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# We dont have all dependencies for armv6l
filter!(p -> arch(p) != "armv6l", platforms)
# This platform fails with
#
#     libtool: link: (cd .libs/librsvg-2.lax/librsvg_c_api.a && ar x "/workspace/srcdir/librsvg-2.52.4/./.libs/librsvg_c_api.a")
#     libtool:   error: object name conflicts in archive: .libs/librsvg-2.lax/librsvg_c_api.a//workspace/srcdir/librsvg-2.52.4/./.libs/librsvg_c_api.a
#
# which seems to be the same as https://github.com/lovell/sharp-libvips/issues/109.  It may
# have been solved by https://github.com/rust-lang/compiler-builtins/pull/444.
filter!(p -> !Sys.isapple(p) || arch(p) != "aarch64", platforms)
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
    Dependency("Libcroco_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:c, :rust])
