# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libpthread_stubs"
version_string = "0.5"
version = VersionNumber(version_string)

# Collection of sources required to build libpthread-stubs
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libpthread-stubs-$(version_string).tar.xz",
                  "59da566decceba7c2a7970a4a03b48d9905f1262ff94410a649224e33d2442bc"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpthread-stubs-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p->!(Sys.islinux(p) || Sys.isfreebsd(p)))

products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
