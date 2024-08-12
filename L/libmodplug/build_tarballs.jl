# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libmodplug"
version = v"0.8.9"

# Collection of sources required to build libmodplug
sources = [
    ArchiveSource("https://downloads.sourceforge.net/modplug-xmms/libmodplug-$(version).0.tar.gz",
                  "457ca5a6c179656d66c01505c0d95fafaead4329b9dbaa0f997d00a3508ad9de"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libmodplug-*/
sed -i 's/-ffast-math//g' configure # This should be a real patch, but `sed` is quicker
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p->arch(p) != "armv6l" && !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmodplug", :libmodplug),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
