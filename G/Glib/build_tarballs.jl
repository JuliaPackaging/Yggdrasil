using BinaryBuilder

name = "Glib"
version = v"2.59.0"

# Collection of sources required to build Glib
sources = [
    ArchiveSource("https://ftp.gnome.org/pub/gnome/sources/glib/$(version.major).$(version.minor)/glib-$(version).tar.xz",
                  "664a5dee7307384bb074955f8e5891c7cecece349bbcc8a8311890dc185b428e"),
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

export NOCONFIGURE=true
export LDFLAGS="${LDFLAGS} -L${libdir}"
export CPPFLAGS="-I${prefix}/include"

./autogen.sh

if [[ "${target}" == i686-linux-musl ]]; then
    # Small hack: swear that we're cross-compiling.  Our `i686-linux-musl` is
    # bugged and it can run only a few programs, with the result that the
    # configure test to check whether we're cross-compiling returns that we're
    # doing a native build, but then it fails to run a bunch of programs during
    # other tests.
    sed -i 's/cross_compiling=no/cross_compiling=yes/' configure
fi

./configure --cache-file=glib.cache --with-libiconv=gnu --prefix=${prefix} --host=${target}
find -name Makefile -exec sed -i 's?/workspace/destdir/bin/msgfmt?/usr/bin/msgfmt?g' '{}' \;

make -j${nproc}
make install
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
    Dependency("Libffi_jll"),
    Dependency("Gettext_jll"),
    Dependency("PCRE_jll"),
    Dependency("Zlib_jll"),
    Dependency("Libmount_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
