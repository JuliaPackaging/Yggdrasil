using BinaryBuilder

name = "Glib"
version = v"2.59.0"

# Collection of sources required to build Glib
sources = [
    "https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz" =>
    "664a5dee7307384bb074955f8e5891c7cecece349bbcc8a8311890dc185b428e",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/glib-*/

# Get a local gettext for msgfmt cross-building
apk add gettext

# Provide answers to a few configure questions automatically
cat > glib.cache <<END
glib_cv_stack_grows=no
glib_cv_uscore=no
END

./autogen.sh LDFLAGS="${LDFLAGS} -L$prefix/lib" CPPFLAGS=-I$prefix/include --enable-libmount=no --cache-file=glib.cache --with-libiconv=gnu --prefix=$prefix --host=$target
find -name Makefile -exec sed -i 's?/workspace/destdir/bin/msgfmt?/usr/bin/msgfmt?g' '{}' \;

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgio", :libgio),
    LibraryProduct("libglib", :libglib),
    LibraryProduct("libgmodule", :libgmodule),
    LibraryProduct("libgobject", :libgobject),
    LibraryProduct("libgthread", :libgthread),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "Libffi_jll",
    "Gettext_jll",
    "PCRE_jll",
    "Zlib_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
