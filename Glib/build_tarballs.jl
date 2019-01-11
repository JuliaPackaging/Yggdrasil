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

if [[ ${target} == *apple-darwin* ]]; then
    export AR=/opt/${target}/bin/${target}-ar
fi
./autogen.sh LDFLAGS=-L$prefix/lib CPPFLAGS=-I$prefix/include --enable-libmount=no --cache-file=glib.cache --with-libiconv=gnu --prefix=$prefix --host=$target

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable FreeBSD for now
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libglib", :libglib)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # We need zlib
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.3/build_Zlib.v1.2.11.jl",
    # We need libffi
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libffi-v3.2.1-0/build_Libffi.v3.2.1.jl",
    # We need gettext
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Gettext-v0.19.8-0/build_Gettext.v0.19.8.jl",
    # We need pcre
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/PCRE-v8.42-2/build_PCRE.v8.42.0.jl",
    # We need iconv
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/Libiconv-v1.15-0/build_Libiconv.v1.15.0.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
