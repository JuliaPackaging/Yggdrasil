# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libexif"
version = v"0.6.26"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/libexif/libexif/releases/download/v$version/libexif-$version.tar.bz2", 
    "0830ed253fceeb60444fb309598bc8a9491d3007dc054aad3a50a347c5597c57"),
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
