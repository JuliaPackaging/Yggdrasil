# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_libpthread_stubs"
version_string = "0.1"
# Upstream version is still 0.1, incremented here for JLL compat reasons. 
version = v"0.1.2"

# Collection of sources required to build libpthread-stubs
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/libpthread-stubs-$(version_string).tar.bz2",
                  "004dae11e11598584939d66d26a5ab9b48d08a00ca2d00ae8d38ee3ac7a15d65"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libpthread-stubs-*/
CPPFLAGS="-I${prefix}/include"
# When compiling for things like ppc64le, we need newer `config.sub` files
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-malloc0returnsnull=no
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
# Build trigger: 1
