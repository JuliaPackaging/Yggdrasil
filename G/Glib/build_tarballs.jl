using BinaryBuilder

name = "Glib"
version = v"2.62.0"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "664a5dee7307384bb074955f8e5891c7cecece349bbcc8a8311890dc185b428e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*/
mkdir build_glib && cd build_glib

SED_SCRIPT=()
# We need to link to iconv, but ninja doesn't know how to do that as libiconv
# doesn't have a pkgconfig file.  Let's give meson a tip.  Note: on PowerPC the
# cross-file has already entries for `c_link_args`, so we have to append.
if [[ "${target}" == powerpc64le-* ]]; then
    SED_SCRIPT+=(-e "s?c_link_args = \[\(.*\)]?c_link_args = [\1, '-liconv']?")
elif [[ "${target}" == *-freebsd* ]]; then
    SED_SCRIPT+=(-e "s?c_link_args = \[]?c_link_args = ['-L${libdir}', '-liconv']?")
else
    SED_SCRIPT+=(-e "s?c_link_args = \[]?c_link_args = ['-liconv']?")
fi
if [[ "${target}" == i686-linux-musl ]]; then
    # We can't run executables for i686-linux-musl in the BB environment
    SED_SCRIPT+=(-e "s?needs_exe_wrapper = false?needs_exe_wrapper = true?" "${MESON_TARGET_TOOLCHAIN}")
elif [[  "${target}" == *-apple-* ]] || [[ "${target}" == *-mingw* ]]; then
    # Tell meson where to find libintl.h
    SED_SCRIPT+=(-e "s?c_args = \[]?c_args = ['-I${prefix}/include']?")
fi

sed -i "${SED_SCRIPT[@]}" \
    "${MESON_TARGET_TOOLCHAIN}"
# We need a new version of objcopy (in binutils) and a native "msgfmt" (in gettext)
apk add binutils gettext
# Get rid of the old objcopy
rm /opt/bin/objcopy

meson .. -Dman=false --cross-file="${MESON_TARGET_TOOLCHAIN}"
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
    Dependency("Libiconv_jll"),
    Dependency("Libffi_jll", v"3.2.1"; compat="~3.2.1"),
    Dependency("Gettext_jll"),
    Dependency("PCRE_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libmount_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
