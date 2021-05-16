using BinaryBuilder

name = "Glib"
version = v"2.68.1"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "241654b96bd36b88aaa12814efc4843b578e55d47440103727959ac346944333"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*/
# Tell meson where to find libintl.h
SED_SCRIPT=(-e "s?c_args = \[]?c_args = ['-I${includedir}']?")
# We need to link to iconv, but ninja doesn't know how to do that as libiconv
# doesn't have a pkgconfig file.  Let's give meson a tip.  Note: on PowerPC the
# cross-file has already entries for `c_link_args`, so we have to append.
if [[ "${target}" == powerpc64le-* ]]; then
    SED_SCRIPT+=(-e "s?c_link_args = \[\(.*\)]?c_link_args = [\1, '-liconv']?")
elif [[ "${target}" == *-freebsd* ]]; then
    SED_SCRIPT+=(-e "s?c_link_args = \[]?c_link_args = ['-L${libdir}', '-liconv']?")
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
else
    SED_SCRIPT+=(-e "s?c_link_args = \[]?c_link_args = ['-liconv']?")
fi

sed -i "${SED_SCRIPT[@]}" \
    "${MESON_TARGET_TOOLCHAIN}"

mkdir build_glib && cd build_glib
meson .. -Dman=false --cross-file="${MESON_TARGET_TOOLCHAIN}" "${MESON_FLAGS[@]}"
ninja -j${nproc}
ninja install
"""

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
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Host gettext needed for "msgfmt"
    HostBuildDependency("Gettext_jll"),
    Dependency("Libiconv_jll"),
    Dependency("Libffi_jll", v"3.2.1"; compat="~3.2.1"),
    Dependency("Gettext_jll"),
    Dependency("PCRE_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libmount_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
