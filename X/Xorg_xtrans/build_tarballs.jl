# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xtrans"
version = v"1.5.1"

# Collection of sources required to build xtrans
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/xtrans-$(version).tar.xz",
                  "dea80fbd8c3c941495b4b1d2785cb652815d016849a0d2ef90d1140de916993e"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/xtrans-*/
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
