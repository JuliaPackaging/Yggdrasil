using BinaryBuilder

name = "Glib"
version = v"2.76.5"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "ed3a9953a90b20da8e5578a79f7d1c8a532eacbe2adac82aa3881208db8a3abe"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*/
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
    # be a problem at runtim.  This flag allows having undefined symbols.
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

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libgio-2", "libgio-2.0"], :libgio),
    LibraryProduct(["libglib-2", "libglib-2.0"], :libglib),
    LibraryProduct(["libgmodule-2", "libgmodule-2.0"], :libgmodule),
    LibraryProduct(["libgobject-2", "libgobject-2.0"], :libgobject),
    LibraryProduct(["libgthread-2", "libgthread-2.0"], :libgthread),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Libffi_jll", v"3.2.2"; compat="~3.2.2"),
    # Gettext is only needed on macOS, as far as I could see
    Dependency("Gettext_jll", v"0.21.0"; compat="=0.21.0"),
    Dependency("PCRE2_jll"; compat="10.35"),
    Dependency("Zlib_jll"),
    Dependency("Libmount_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"6")
