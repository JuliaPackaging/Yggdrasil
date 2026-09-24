# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GTK3"
version = v"3.24.50"

# Collection of sources required to build GTK
sources = [
    GitSource("https://gitlab.gnome.org/GNOME/gtk.git",
              "93f05958bd683cb573236bd2a4cede68160595ca"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*

# We need to run some commands with a native Glib
apk add glib-dev gtk+3.0

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata

# `${bindir}/wayland_scanner` is a symbolic link that contains `..` path elements.
# These are not properly normalized: They are normalized before expanding the symbolic link `/workspace/destdir`,
# and this leads to a broken reference. We resolve the path manually.
#
# Since this symbolic link is working in the shell, and since `pkg-config` outputs the expected values,
# I think this may be a bug in `meson`.
#
# The file `wayland-scanner.pc` is mounted multiple times (and is also available via symbolic links).
# Fix it for all relevant mount points.
for destdir in /workspace/x86_64-linux-musl*/destdir; do
    prefix_path=$(echo $destdir | sed -e 's+/destdir$++')/$(readlink ${host_bindir}/wayland-scanner | sed -e 's+^[.][.]/[.][.]/++' | sed -e 's+/bin/wayland-scanner$++')
    if [ -e ${prefix_path}/lib/pkgconfig/wayland-scanner.pc ]; then
        sed -i -e "s+prefix=.*+prefix=${prefix_path}+" ${prefix_path}/lib/pkgconfig/wayland-scanner.pc
    fi
done

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11_backend=false -Dwayland_backend=false)
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland_backend=false)
elif [[ "${target}" == *-mingw* ]]; then
    # Need to tell we're targeting at least Windows 7 so that `GC_ALLGESTURES` is defined
    sed -ri "s/^c_args = \[(.*)\]/c_args = [\1, '-DWINVER=_WIN32_WINNT_WIN7']/" ${MESON_TARGET_TOOLCHAIN}
fi

meson setup builddir \
    --buildtype=release \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=false \
    -Ddemos=false \
    -Dexamples=false \
    -Dtests=false \
    "${FLAGS[@]}"
meson compile -C builddir
meson install -C builddir

# Remove temporary links
rm ${bindir}/gdk-pixbuf-pixdata ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#TODO platforms = filter!(p -> arch(p) != "armv6l", supported_platforms(; experimental=true))
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgailutil-3", :libgailutil3),
    LibraryProduct("libgdk-3", :libgdk3),
    LibraryProduct("libgtk-3", :libgtk3),
]

# Some dependencies are needed only on Linux or Linux and FreeBSD
linux = filter(Sys.islinux, platforms)
linux_freebsd = filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a host Wayland for wayland-scanner
    HostBuildDependency("Wayland_jll"; platforms=linux),
    BuildDependency("Xorg_xorgproto_jll"; platforms=linux_freebsd),
    Dependency("ATK_jll"; compat="2.38.1"),
    Dependency("Cairo_jll"; compat="1.18.5"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("FriBidi_jll"),
    Dependency("Glib_jll"; compat="2.84.3"),
    Dependency("HarfBuzz_jll"),
    Dependency("Libepoxy_jll"; compat="1.5.11"),
    Dependency("Pango_jll"; compat="1.56.3"),
    Dependency("Wayland_jll"; platforms=linux),
    Dependency("Wayland_protocols_jll"; compat="1.44", platforms=linux),
    Dependency("Xorg_libX11_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXcomposite_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXcursor_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXdamage_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXext_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXfixes_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXi_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXinerama_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXrandr_jll"; platforms=linux_freebsd),
    Dependency("Xorg_libXrender_jll"; platforms=linux_freebsd),
    Dependency("at_spi2_atk_jll"; platforms=linux_freebsd),
    Dependency("gdk_pixbuf_jll"),
    Dependency("iso_codes_jll"),
    Dependency("xkbcommon_jll"; platforms=linux),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
