# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using Pkg

name = "Librsvg"
version = v"2.54.7"

# Collection of sources required to build librsvg
sources = [
    ArchiveSource("https://download.gnome.org/sources/librsvg/$(version.major).$(version.minor)/librsvg-$(version).tar.xz",
                  "29a183cc855544d8a90de50720d5358a488c22118fffcb541aa0e790005d0966"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/librsvg-*/

autoreconf -fiv

# Delete misleading libtool files
rm -vf ${prefix}/lib/*.la

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
# Rust toolchain 1.65.0 not available on platform aarch64-unknown-freebsd or riscv64-linux-gnu
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)

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
    HostBuildDependency(PackageSpec(; name="gdk_pixbuf_jll", version=v"2.42.8")),
    BuildDependency(PackageSpec(; name="Xorg_xorgproto_jll", version=v"2019.2.0+2")),
    Dependency("gdk_pixbuf_jll"; compat="2.42.8"),
    Dependency("Pango_jll"; compat="1.47.0"),
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("Glib_jll"; compat="2.74.0"), # For GIO
    # We had to restrict compat with XML2 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10965#issuecomment-2798501268
    # Updating to a newer XML2 version is likely possible without problems but requires rebuilding this package
    Dependency("XML2_jll"; compat="2.9.14 - 2.13"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.6",
    compilers=[:c, :rust],
    preferred_rust_version=v"1.65.0",
)
