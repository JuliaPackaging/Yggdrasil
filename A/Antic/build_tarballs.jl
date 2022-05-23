# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

name = "Antic"
upstream_version = v"0.2.5"
build_for_julia16_or_newer = true
version_offset = build_for_julia16_or_newer ? v"0.0.1" : v"0.0.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/wbhart/antic.git", "a071e65dd82884b3a048c6436830cea6c6ce59b8"),
#    ArchiveSource("https://github.com/wbhart/antic/archive/v$(upstream_version).tar.gz",
#                  "78a06f67352d7a94905a5399ef0f0add1a34e90fb0c30b8dbdedf8254393e9dd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd antic*/
if [[ ${target} == *musl* ]]; then
   export CFLAGS=-D_GNU_SOURCE=1;
elif [[ ${target} == *mingw* ]]; then
   sed -i -e "s#/lib\>#/$(basename ${libdir})#g" configure
   extraflags=--build=MINGW${nbits};
fi
./configure --prefix=$prefix --disable-static --enable-shared --with-gmp=$prefix --with-mpfr=$prefix --with-flint=$prefix ${extraflags}
make -j${nproc}
make install LIBDIR=$(basename ${libdir})
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=build_for_julia16_or_newer)

# The products that we will ensure are always built
products = [
    LibraryProduct("libantic", :libantic)
]

# Dependencies that must be installed before this package can be built
v = build_for_julia16_or_newer ? v"200.800.101" : v"200.800.100"
dependencies = [
    Dependency("FLINT_jll", v; compat = "~$v"),
    Dependency("GMP_jll", build_for_julia16_or_newer ? v"6.2.0" : v"6.1.2"),
    Dependency("MPFR_jll", build_for_julia16_or_newer ? v"4.1.1" : v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = build_for_julia16_or_newer ? "1.6" : "1.0-1.5")
