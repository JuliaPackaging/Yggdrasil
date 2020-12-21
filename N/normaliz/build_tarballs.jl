# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec
name = "normaliz"
version = v"300.800.900"
upstream_version = v"3.8.9"

# Normaliz_jll versions are decoupled from the upstream versions.
# Whenever we package a new official Normaliz release, we initially map its
# version X.Y.Z to X00.Y00.Z00 (i.e., multiply each component by 100).
# So for example version 2.6.3 would become 200.600.300.
#
# Moreover, all our packages using Normaliz_jll use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor tweaks.
# If a rebuild of the JLL is needed which keeps the upstream version identical
# but breaks ABI compatibility for any reason, we can increment the minor version
# e.g. go from 200.600.300 to 200.601.300.
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 2.7.0 to 200.690.000.
#
# There is currently no plan to change the major version (except when Normaliz itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/Normaliz/Normaliz/releases/download/v$(upstream_version)/normaliz-$(upstream_version).tar.gz",
                  "a4c3eda39ffe42120adfd3bda9433b01d9965516e3f98e401b62752a54bee5dd")
]

# Bash recipe for building across all platforms
script = raw"""
cd normaliz-*
# avoid libtool problems
rm "${prefix}/lib/libgmpxx.la"
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} --with-flint=$prefix --with-nauty=$prefix --with-gmp=$prefix CPPFLAGS=-I$prefix/include LDFLAGS=-L${libdir}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# windows build would require MPIR instead of GMP for 'long long'
platforms = filter(!Sys.iswindows, supported_platforms())
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libnormaliz", :libnormaliz),
    ExecutableProduct("normaliz", :normaliz)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
    Dependency(PackageSpec(name="FLINT_jll", version=VersionSpec("200.700"))),
    Dependency(PackageSpec(name="nauty_jll", uuid="55c6dc9b-343a-50ca-8ff2-b71adb3733d5")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
