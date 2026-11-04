# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.58.2"

# Collection of sources required to build Pango: https://download.gnome.org/sources/pango/
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz",
                  "342385b6ca3b7c73455d7c80a13b7dbe4489e00bc3bd4c5bd6ed4dce421e374a"),
]

# Bash recipe for building across all platforms
script = raw"""

apk add glib-dev

cd $WORKSPACE/srcdir/pango*

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
fi

# If we want libpangoft2 on Windows we need to explicitly enable fontconfig and freetype
# See <https://gitlab.gnome.org/GNOME/pango/-/blob/main/README.win32.md>.

# We need a newer meson.  Install it into a private directory instead of using
# `pip install --upgrade`: upgrading in place requires uninstalling the meson
# that ships in the rootfs, and removing files under
# /usr/lib/python3.9/site-packages fails with an I/O error on the builders.
python3 -m pip install --ignore-installed --target=/tmp/meson meson==1.11.2
export PYTHONPATH="/tmp/meson${PYTHONPATH:+:${PYTHONPATH}}"
export PATH="/tmp/meson/bin:${PATH}"
meson --version

# meson 1.11 no longer defaults `subsystem` to `system` in cross files, so
# Pango's unconditional `host_machine.subsystem()` call on darwin aborts
# configuration.  Set it explicitly to `darwin`, which reproduces meson's
# pre-1.11 default.  Do *not* use `macos` here: that switches on Pango's
# CoreText/quartz backend, which has never been part of this JLL and does not
# compile (pango/pangocoretext.c:263 assigns a PangoCoreTextFontMap* to a
# PangoFontMap*, which our clang rejects).
if [[ ${target} == *darwin* ]]; then
    sed -i "/\[host_machine\]/,/^$/ s/system = 'darwin'/system = 'darwin'\nsubsystem = 'darwin'/" "$MESON_TARGET_TOOLCHAIN"
fi

meson setup build \
    --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=disabled \
    -Dfontconfig=enabled \
    -Dfreetype=enabled
ninja -C build -j${nproc}
ninja -C build install

install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpango", "libpango-1", "libpango-1.0"], :libpango),
    LibraryProduct(["libpangocairo", "libpangocairo-1", "libpangocairo-1.0"], :libpangocairo),
    LibraryProduct(["libpangoft2", "libpangoft2-1", "libpangoft2-1.0"], :libpangoft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency("Gettext_jll"),
    HostBuildDependency("gperf_jll"),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p -> Sys.isfreebsd(p) || Sys.islinux(p), platforms)),
    Dependency("Cairo_jll"; compat="1.18.5"),
    Dependency("Fontconfig_jll"; compat="2.17.1"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("FriBidi_jll"; compat="1.0.17"),
    Dependency("Glib_jll"; compat="2.88.3"),
    Dependency("HarfBuzz_jll"; compat="100.14003"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
