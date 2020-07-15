# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "acl"
version = v"2.2.53"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://download.savannah.nongnu.org/releases/acl/acl-2.2.53.tar.gz", "06be9865c6f418d851ff4494e12406568353b891ffe1f596b34693c387af26c7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/acl-*/
export CPPFLAGS="-I${includedir} -fPIC -DPIC"
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
install_license doc/COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [p for p in supported_platforms() if p isa Linux]

# The products that we will ensure are always built
products = [
    LibraryProduct("libacl", :libacl),
    ExecutableProduct("getfacl", :getfacl),
    ExecutableProduct("setfacl", :setfacl),
    ExecutableProduct("chacl", :chacl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Attr_jll", uuid="1fd713ca-387f-5abc-8002-d8b8b1623b73"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
