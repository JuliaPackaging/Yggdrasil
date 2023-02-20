# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libexif"
version = v"0.6.24"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libexif/libexif.git", 
    "a7121eb4075df87c95004ca0c9d5385f23e6d777"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libexif/
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
platforms = supported_platforms(; experimental=true)


# The products that we will ensure are always built
products = [
    LibraryProduct("libexif", :libexif)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
