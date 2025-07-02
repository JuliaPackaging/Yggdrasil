# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
using BinaryBuilderBase: get_addable_spec

name = "GTK4"
version = v"4.18.6"

# Collection of sources required to build GTK
sources = [
    ArchiveSource("https://download.gnome.org/sources/gtk/$(version.major).$(version.minor)/gtk-$(version).tar.xz",
                  "e1817c650ddc3261f9a8345b3b22a26a5d80af154630dedc03cc7becefffd0fa"),
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
               "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
    FileSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v10.0.0.tar.bz2",
               "ba6b430aed72c63a3768531f6a3ffc2b0fde2c57a3b251450dcf489a894f0894"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/gtk*

# We need to run some commands with a native Glib
apk update
apk add glib-dev py3-pip

# we need a newer meson (>= 1.5.0)
pip3 install -U meson

# meson shouldn't be so opinionated (mesonbuild/meson#4542 is incomplete)
sed -i '/Werror=unused-command-line-argument/d' /usr/lib/python3.9/site-packages/mesonbuild/compilers/mixins/clang.py

# This is awful, I know
ln -sf /usr/bin/glib-compile-resources ${bindir}/glib-compile-resources
ln -sf /usr/bin/glib-compile-schemas ${bindir}/glib-compile-schemas
ln -sf /usr/bin/gdk-pixbuf-pixdata ${bindir}/gdk-pixbuf-pixdata

if [[ "${target}" == x86_64-linux-musl* ]]; then
    # On x86_64-linux-musl, there are still some libraries that are pulled in from the standard paths instead of from `$libdir`.
    # This fixes that.
    rm /lib/libmount.so*
    rm /lib/libblkid.so*
    rm /usr/lib/libexpat.so*
    rm /usr/lib/libffi.so*
fi

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

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # macOS SDK 10.15 or newer is required to build GTK
    export MACOSX_DEPLOYMENT_TARGET=10.15
    rm -rf /opt/${target}/${target}/sys-root/System
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX10.15.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX10.15.sdk/System MacOSX10.15.sdk/usr
fi

if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir
    tar xjf mingw-w64-v10.0.0.tar.bz2
    cd mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install
fi

FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS+=(-Dx11-backend=false -Dwayland-backend=false)
    if [[ "${target}" == x86_64-* ]]; then
        # There is a linker error, the symbol `___cpu_features2` is not found.
        # We might be able fix this by telling meson about a library that's missing,
        # if that library exists on macOS.
        FLAGS+=(-Df16c=disabled)
    fi
elif [[ "${target}" == *-freebsd* ]]; then
    FLAGS+=(-Dwayland-backend=false)
fi

cd $WORKSPACE/srcdir/gtk*

meson setup builddir \
    --buildtype=release \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dmedia-gstreamer=disabled \
    -Dintrospection=disabled \
    -Dvulkan=disabled \
    -Dbuild-demos=false \
    -Dbuild-examples=false \
    -Dbuild-tests=false \
    -Dbuild-testsuite=false \
    "${FLAGS[@]}"
meson compile -C builddir
meson install -C builddir

install_license COPYING

# post-install script is disabled when cross-compiling
glib-compile-schemas ${prefix}/share/glib-2.0/schemas

# Remove temporary links
rm ${bindir}/gdk-pixbuf-pixdata ${bindir}/glib-compile-{resources,schemas}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# There is a linker error:
# The symbol `g_libintl_bindtextdomain`, required by `gdk_pixbuf_jll`, is not defined.
# This should probably be defined by `Glib_jll`. I don't know exactly what is going on.
# In particular, I don't understand where the `g_` prefix is coming from.
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libgtk-4", :libgtk4),
    ExecutableProduct("gtk4-builder-tool", :gtk4_builder_tool),
]

x11_platforms = filter(p -> Sys.islinux(p) || Sys.isfreebsd(p), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    # Need a native `sassc`
    HostBuildDependency("SassC_jll"),
    # Need a host Wayland for wayland-scanner
    #TODO HostBuildDependency("Wayland_jll"; platforms=x11_platforms),
    HostBuildDependency(get_addable_spec("Wayland_jll", v"1.23.1+0"); platforms=x11_platforms),
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
    # Build needs a header from but does not link to libdrm
    BuildDependency("libdrm_jll"; platforms=x11_platforms),
    Dependency("Cairo_jll"; compat="1.18.5"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("FriBidi_jll"),
    Dependency("GettextRuntime_jll"; compat="0.22.4"),
    Dependency("Glib_jll"; compat="2.84.3"),
    Dependency("Graphene_jll"; compat="1.10.8"),
    Dependency("HarfBuzz_jll"),
    Dependency("Libepoxy_jll"; compat="1.5.11"),
    Dependency("Libtiff_jll"; compat="4.7.1"),
    Dependency("PCRE2_jll"; compat="10.42"),
    Dependency("Pango_jll"; compat="1.56.3"),
    Dependency("Wayland_jll"; platforms=x11_platforms),
    Dependency("Wayland_protocols_jll"; compat="1.44", platforms=x11_platforms),
    Dependency("Xorg_libX11_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXcursor_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXdamage_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXext_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXfixes_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXi_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXinerama_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrandr_jll"; platforms=x11_platforms),
    Dependency("Xorg_libXrender_jll"; platforms=x11_platforms),
    Dependency("gdk_pixbuf_jll"),
    Dependency("iso_codes_jll"),
    Dependency("xkbcommon_jll"; platforms=x11_platforms),
]

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 8 to support `__VA_OPT__`
# We need at least GCC 9 to avoid linker problems on x86_64-linux-musl
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"9")
