using BinaryBuilder

name = "Glib"
version = v"2.68.3"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "e7e1a3c20c026109c45c9ec4a31d8dcebc22e86c69486993e565817d64be3138"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*/

if [[ "${target}" == *-freebsd* ]]; then
    # Our FreeBSD libc has `environ` as undefined symbol, so the linker will
    # complain if this symbol is used in the built library, even if this won't
    # be a problem at runtim.  This flag allows having undefined symbols.
    MESON_FLAGS=(-Db_lundef=false)

    # Adapt patch relative to `xattr` from
    # http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/devel/glib2/patches/patch-meson.build?rev=1.2&content-type=text/x-cvsweb-markup.
    # Quoting the comment:
    #     Don't fail if getxattr is not available. The code is already ready
    #     for this case with some small configure changes.
    atomic_patch -p1 ../patches/freebsd-have_xattr.patch
fi

mkdir build_glib && cd build_glib
meson --cross-file="${MESON_TARGET_TOOLCHAIN}" \
    --buildtype=release \
    -Dman=false \
    -Diconv=external \
    "${MESON_FLAGS[@]}" \
    ..
ninja -j${nproc}
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
    Dependency("PCRE_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libmount_jll"; platforms=filter(Sys.islinux, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
