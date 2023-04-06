# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GlibNetworking"
version = v"2.74.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://download.gnome.org/sources/glib-networking/$(version.major).$(version.minor)/glib-networking-$(version).tar.xz", "1f185aaef094123f8e25d8fa55661b3fd71020163a0174adb35a37685cda613b")
]

# Bash recipe for building across all platforms
script = raw"""

# We need to run some commands with a native Glib
apk add glib-dev
# Copied from GTK4 recipe
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
# Remove gio-2.0 pkgconfig file so that it isn't picked up by post-install script.
rm ${prefix}/lib/pkgconfig/gio-2.0.pc


cd $WORKSPACE/srcdir
install_license glib-networking-*/COPYING

MESON_FLAGS=(--cross-file="${MESON_TARGET_TOOLCHAIN}")
MESON_FLAGS+=(--buildtype=release)
MESON_FLAGS+=(-Dopenssl=enabled)

meson "${MESON_FLAGS[@]}" glib-networking-*/
ninja -j${nproc} --verbose
ninja install


# Remove temporary links
rm ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.iswindows(p), supported_platforms())
platforms_windows = filter!(p -> Sys.iswindows(p), supported_platforms())


# The products that we will ensure are always built
products = [
    FileProduct("lib/gio/modules/libgioenvironmentproxy.so", :libgioenvironmentproxy),
    FileProduct("lib/gio/modules/libgioopenssl.so", :libgioopenssl)
]

products_windows = [
    FileProduct("bin/libgioenvironmentproxy.dll", :libgioenvironmentproxy),
    FileProduct("bin/libgioopenssl.dll", :libgioopenssl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll")
    Dependency("OpenSSL_jll"; compat="1.1.10")
    Dependency("Glib_jll"; compat="2.74.0")
]

include("../../fancy_toys.jl")

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_windows)))
    build_tarballs(ARGS, name, version, sources, script, platforms_windows, products_windows, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end
