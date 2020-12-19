# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

name = "Arb"
version = v"200.1900.000"
upstream_version = v"2.19.0"

# Arb_jll versions are decoupled from the upstream versions.
# Whenever we package a new official Arb release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.19.0 would become 200.1900.000.
#
# Moreover, all our packages using Arb_jll use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version (except when Arb itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/fredrik-johansson/arb/archive/$(upstream_version).tar.gz",
                  "0aec6b492b6e9a543bdb3287a91f976951e2ba74fd4de942e692e21f7edbcf13"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd arb*/

if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE=1
elif [[ ${target} == *mingw* ]]; then
   # /lib is hardcoded in many places
   sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure
   # MSYS_NT-6.3 is not detected as MINGW
   extraflags=--build=MINGW${nbits}
fi

./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-flint=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libarb", :libarb)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="FLINT_jll", version=VersionSpec("200.700"))),
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
