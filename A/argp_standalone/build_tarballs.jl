# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "argp_standalone"
version = v"1.3.0"

# Collection of sources required to build argp-standalone
sources = [
    ArchiveSource("http://www.lysator.liu.se/~nisse/misc/argp-standalone-$(version.major).$(version.minor).tar.gz",
                  "dec79694da1319acd2238ce95df57f3680fea2482096e483323fddf3d818d8be"),
    FileSource("https://www.gnu.org/licenses/old-licenses/gpl-2.0.txt", "8177f97513213526df2cf6184d8ff986c675afb514d4e68a404010521b880643"; filename="LICENSE"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/argp-*/
CFLAGS="-fPIC" ./configure --prefix=${prefix} --host=${target}
make -j${nproc}
install_license $WORKSPACE/srcdir/LICENSE
install -D -m644 argp.h ${includedir}/argp.h
install -D -m755 libargp.a ${libdir}/libargp.a
"""

# Select Unix platforms
platforms = [p for p in supported_platforms() if Sys.islinux(p) && libc(p) == "musl"]

# The products that we will ensure are always built
products = [
    FileProduct("lib/libargp.a", :libargp),
    FileProduct("include/argp.h", :argp_h),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
