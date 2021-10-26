# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "mtdev"
version = v"1.1.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://bitmath.org/code/mtdev/mtdev-$version.tar.gz", "1325f389a2f25cd5f5a8ea4d29aad24aa7c3ec30401d679400dd79eb9c0a8dbb"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mtdev-*/
update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms(; experimental=true))

# The products that we will ensure are always built
products = [
    LibraryProduct("libmtdev", :libmtdev)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
