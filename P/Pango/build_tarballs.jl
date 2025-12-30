# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.57.0"

# Collection of sources required to build Pango: https://download.gnome.org/sources/pango/
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz",
                  "890640c841dae77d3ae3d8fe8953784b930fa241b17423e6120c7bfdf8b891e7"),
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

# We need to update pip
python3 -m pip install --upgrade pip setuptools wheel
pip3 install gi-docgen
# We need a newer meson
python3 -m pip install --upgrade meson

mkdir build && cd build
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=disabled \
    -Dfontconfig=enabled \
    -Dfreetype=enabled \
    ..
ninja -j${nproc}
ninja install

install_license ../COPYING
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
    Dependency("Fontconfig_jll"; compat="2.16.0"),
    Dependency("FreeType2_jll"; compat="2.13.4"),
    Dependency("FriBidi_jll"; compat="1.0.17"),
    Dependency("Glib_jll"; compat="2.84.0"),
    Dependency("HarfBuzz_jll"; compat="8.5.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
