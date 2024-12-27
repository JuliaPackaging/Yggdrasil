# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Xorg_xtrans"
version = v"1.5.0"

# Collection of sources required to build xtrans
sources = [
    ArchiveSource("https://www.x.org/archive/individual/lib/xtrans-$(version).tar.xz",
               "1ba4b703696bfddbf40bacf25bce4e3efb2a0088878f017a50e9884b0c8fb1bd"),
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
