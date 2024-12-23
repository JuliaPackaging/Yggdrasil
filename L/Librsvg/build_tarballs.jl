# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Librsvg"
version = v"2.59.2"

# Collection of sources required to build librsvg
sources = [
    ArchiveSource("https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz",
                  "ecd293fb0cc338c170171bbc7bcfbea6725d041c95f31385dc935409933e4597"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*

#TODO autoreconf -fiv
#TODO 
#TODO # Delete misleading libtool files
#TODO rm -vf ${prefix}/lib/*.la
#TODO 
#TODO # On most platforms we have to use `${rust_target}` as `host`
#TODO FLAGS=(--host=${rust_target})
#TODO if [[ "${target}" == *-mingw* ]]; then
#TODO     # On Windows using `${rust_target}` wouldn't work:
#TODO     #
#TODO     #     Invalid configuration `x86_64-pc-windows-gnu': Kernel `windows' not known to work with OS `gnu'.
#TODO     #
#TODO     # Then we have to use `RUST_TARGET` to set the Rust target.  I haven't found
#TODO     # a combination host and RUST_TARGET that would work on all platforms.  If
#TODO     # you do, let me know!
#TODO     FLAGS=(--host=${target} RUST_TARGET="${rust_target}" LIBS="-luserenv -lbcrypt")
#TODO fi
#TODO 
#TODO ./configure \
#TODO     --build=${MACHTYPE} \
#TODO     --prefix=${prefix} \
#TODO     --disable-static \
#TODO     --enable-pixbuf-loader \
#TODO     --disable-introspection \
#TODO     --disable-gtk-doc-html \
#TODO     --enable-shared \
#TODO     "${FLAGS[@]}"
#TODO make
#TODO make install
#TODO install_license COPYING.LIB

meson setup builddir --cross-file=${MESON_TARGET_TOOLCHAIN} --prefix=${prefix}
meson compile -C builddir
meson install -C builddir
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# Rust is not supported on aarch64-*-freebsd
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
#TODO # We dont have all dependencies for armv6l
#TODO filter!(p -> arch(p) != "armv6l", platforms)
#TODO # Rust toolchain for i686 Windows is unusable
#TODO filter!(p -> !Sys.iswindows(p) || arch(p) != "i686", platforms)

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
    Dependency("Pango_jll"; compat="1.55.5"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", compilers=[:c, :rust])
