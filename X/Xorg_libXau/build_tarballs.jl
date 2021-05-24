# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libXau"
version = v"1.0.9"

# Collection of sources required to build libXau
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libXau-$(version).tar.bz2",
                  "ccf8cbf0dbf676faa2ea0a6d64bcc3b6746064722b606c8c52917ed00dcb73ec"),
]

version = v"1.0.10" # <-- This version is a lie, we need it to bump the version to build for more platforms

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libXau-*/
CPPFLAGS="-I${includedir}"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms(; experimental=true))

products = [
    LibraryProduct("libXau", :libXau),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Xorg_xproto_jll")
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
