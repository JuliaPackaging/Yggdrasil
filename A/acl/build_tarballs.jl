# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "acl"
version = v"2.3.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://download.savannah.nongnu.org/releases/acl/acl-$(version).tar.xz",
                  "c0234042e17f11306c23c038b08e5e070edb7be44bef6697fb8734dcff1c66b1")
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
platforms = filter!(Sys.islinux, supported_platforms(; experimental=true))

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
