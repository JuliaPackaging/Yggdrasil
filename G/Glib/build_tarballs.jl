using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "Glib"
version = v"2.86.3"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "b3211d8d34b9df5dca05787ef0ad5d7ca75dec998b970e1aab0001d229977c65"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*
install_license COPYING

# meson shouldn't be so opinionated (mesonbuild/meson#4542 is incomplete)
sed -i '/Werror=unused-command-line-argument/d' /usr/lib/python3.9/site-packages/mesonbuild/compilers/mixins/clang.py

if [[ "${target}" == *-freebsd* ]]; then
    # Adapt patch relative to `xattr` from
    # http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/devel/glib2/patches/patch-meson.build?rev=1.2&content-type=text/x-cvsweb-markup.
    # Quoting the comment:
    #     Don't fail if getxattr is not available. The code is already ready
    #     for this case with some small configure changes.
    atomic_patch -p1 ../patches/freebsd-have_xattr.patch
fi

mkdir build_glib && cd build_glib

MESON_FLAGS=(--cross-file="${MESON_TARGET_TOOLCHAIN}")
MESON_FLAGS+=(--buildtype=release)
MESON_FLAGS+=(-Dman=false)
MESON_FLAGS+=(-Dtests=false)

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtime. This flag allows having undefined symbols.
    MESON_FLAGS+=(-Db_lundef=false)
fi

if [[ "${target}" != *-mingw* ]]; then
    # on Windows, we can't build both static and shared libraries at the same time,
    # so stick to the shared one until we have a need for a static build
    MESON_FLAGS+=(--default-library both)
fi

meson "${MESON_FLAGS[@]}" ..

# Meson beautifully forces thin archives, without checking whether the dynamic linker
# actually supports them: <https://github.com/mesonbuild/meson/issues/10823>.  Let's remove
# the (deprecated...) `T` option to `ar`
sed -i.bak 's/csrDT/csrD/' build.ninja

ninja -j${nproc} --verbose
ninja install
"""

sources, script = require_macos_sdk("10.13", sources, script)

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgio-2", "libgio-2.0"], :libgio),
    LibraryProduct(["libglib-2", "libglib-2.0"], :libglib),
    LibraryProduct(["libgmodule-2", "libgmodule-2.0"], :libgmodule),
    LibraryProduct(["libgobject-2", "libgobject-2.0"], :libgobject),
    LibraryProduct(["libgthread-2", "libgthread-2.0"], :libgthread),
    LibraryProduct(["libgirepository-2", "libgirepository-2.0"], :libgirepository),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll"),
    Dependency("GettextRuntime_jll"; compat="0.22.4"),
    Dependency("Libffi_jll"; compat="~3.4.7"),
    Dependency("Libiconv_jll"),
    Dependency("Libmount_jll"; platforms=filter(Sys.islinux, platforms)),
    Dependency("PCRE2_jll"; compat="10.42.0"),
    Dependency("Zlib_jll"; compat="1.2.12"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"6")
