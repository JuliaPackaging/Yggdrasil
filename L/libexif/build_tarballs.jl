# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libexif"
version = v"0.6.24"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libexif/libexif/releases/download/v0.6.24/libexif-0.6.24.tar.bz2", 
    "d47564c433b733d83b6704c70477e0a4067811d184ec565258ac563d8223f6ae"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libexif-*/
if [[ "${target}" == powerpc64le-* ]] || [[ "${target}" == *-freebsd* ]]; then
    # Install `autopoint` and other tools needed by `autoreconf`
    apk add gettext-dev
    # Rebuild the configure script to convince it to build the shared library
    autoreconf -vi
fi
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libexif", :libexif)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
