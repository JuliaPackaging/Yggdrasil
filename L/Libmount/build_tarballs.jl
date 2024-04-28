# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Libmount"
version_string = "2.40"
version = VersionNumber(version_string)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v$(version.major).$(version.minor)/util-linux-$(version_string).tar.xz",
                  "d57a626081f9ead02fa44c63a6af162ec19c58f53e993f206ab7c3a6641c2cd7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/util-linux-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-all-programs --enable-libblkid --enable-libmount
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter!(Sys.islinux, supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libmount", :libmount)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
