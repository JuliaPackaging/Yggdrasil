# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Pango"
version = v"1.50.14"

# Collection of sources required to build Pango
sources = [
    ArchiveSource("http://ftp.gnome.org/pub/GNOME/sources/pango/$(version.major).$(version.minor)/pango-$(version).tar.xz",
                  "1d67f205bfc318c27a29cfdfb6828568df566795df0cb51d2189cde7f2d581e8"),
    DirectorySource("./bundled"),
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

cd $WORKSPACE/srcdir/pango-*/
# fix a windows build issue: see https://gitlab.gnome.org/GNOME/pango/-/merge_requests/702
atomic_patch -p1 ../patches/dwrite.patch
pip3 install gi-docgen
mkdir build && cd build
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    -Dintrospection=disabled \
    ..
ninja -j${nproc}
ninja install

install_license ../COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> arch(p) != "armv6l", supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpango", "libpango-1", "libpango-1.0"], :libpango),
    LibraryProduct(["libpangocairo", "libpangocairo-1", "libpangocairo-1.0"], :libpangocairo),
    LibraryProduct(["libpangoft2", "libpangoft2-1", "libpangoft2-1.0"], :libpangoft),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Cairo_jll"; compat="1.16.1"),
    Dependency("Fontconfig_jll"),
    Dependency("FreeType2_jll"; compat="2.10.4"),
    Dependency("FriBidi_jll"),
    Dependency("Glib_jll"; compat="2.68.1"),
    Dependency("HarfBuzz_jll"; compat="2.8.1"),
    BuildDependency("Xorg_xorgproto_jll"; platforms=filter(p->Sys.islinux(p)||Sys.isfreebsd(p), platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
