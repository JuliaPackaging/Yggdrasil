# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GlibNetworking"
version = v"2.74.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.gnome.org/GNOME/glib-networking.git", "33de32c0640aab7ccac53ad8e9bc4a7ab5cb5b9d")
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
install_license glib-networking/COPYING

MESON_FLAGS=(--cross-file="${MESON_TARGET_TOOLCHAIN}")
MESON_FLAGS+=(--buildtype=release)
MESON_FLAGS+=(-Dopenssl=enabled)

meson "${MESON_FLAGS[@]}" glib-networking/
ninja -j${nproc} --verbose
ninja install


# Remove temporary links
rm ${prefix}/bin/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> !Sys.isapple(p), supported_platforms())
platforms_macos = filter!(p -> Sys.isapple(p), supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libgioenvironmentproxy", :libgioenvironmentproxy, "lib/gio/modules"),
    LibraryProduct("libgioopenssl", :libgioopenssl, "lib/gio/modules")
]

products_macos = [
    FileProduct("lib/gio/modules/libgioenvironmentproxy.so", :libgioenvironmentproxy),
    FileProduct("lib/gio/modules/libgioopenssl.so", :libgioopenssl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll")
    Dependency("OpenSSL_jll", v"1.1.20+0"; compat="~1.1.20")
    Dependency("Glib_jll", v"2.74.0"; compat="~2.74.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
if any(should_build_platform.(triplet.(platforms_macos)))
    build_tarballs(ARGS, name, version, sources, script, platforms_macos, products_macos, dependencies; julia_compat="1.6")
end
if any(should_build_platform.(triplet.(platforms)))
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
end
