# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.52.2"

# Collection of sources required to build Pango: https://download.gnome.org/sources/pango/
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz",
                  "d0076afe01082814b853deec99f9349ece5f2ce83908b8e58ff736b41f78a96b"),
    ArchiveSource("https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v11.0.0.tar.bz2",
                  "bd0ea1633bd830204cc23a696889335e9d4a32b8619439ee17f22188695fcc5f"),
]

# Bash recipe for building across all platforms
script = raw"""

if [[ "${target}" == *-mingw* ]]; then
    cd $WORKSPACE/srcdir/mingw*/mingw-w64-headers
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target
    make install

    cd ../mingw-w64-crt/
    if [ ${target} == "i686-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib64 --enable-lib32"
    elif [ ${target} == "x86_64-w64-mingw32" ]; then
        _crt_configure_args="--disable-lib32 --enable-lib64"
    fi
    ./configure --prefix=/opt/$target/$target/sys-root --enable-sdk=all --host=$target --enable-wildcard ${_crt_configure_args}
    make -j${nproc}
    make install
fi

cd $WORKSPACE/srcdir/pango*/

if [[ "${target}" == "${MACHTYPE}" ]]; then
    # When building for the host platform, the system libexpat is picked up
    rm /usr/lib/libexpat.so*
fi

# If we want libpangoft2 on Windows we need to explicitly enable fontconfig and freetype
# See <https://gitlab.gnome.org/GNOME/pango/-/blob/main/README.win32.md>.

pip3 install gi-docgen
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
    Dependency("Cairo_jll"; compat="1.18.0"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.13.1"),
    Dependency("FriBidi_jll"),
    Dependency("Glib_jll"; compat="2.74.0"),
    Dependency("HarfBuzz_jll"; compat="2.8.1"),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6", clang_use_lld=false)
