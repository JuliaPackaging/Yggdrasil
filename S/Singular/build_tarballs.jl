# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
import Pkg.Types: VersionSpec

# The version of this JLL is decoupled from the upstream version.
# Whenever we package a new upstream release, we initially map its
# version X.Y.ZpN to X0Y.Z00.N00. So for example version 4.1.3p5 becomes 401.300.500.
#
# This reflects the fact that 4.2.0 will only be made if there is a change to
# Singular language itself, i.e., this is a pretty major change. The third digit
# is changed for regular interim releases, and corresponds roughly to a semver
# minor release; and the `p5` truly is a patch level.
#
# Moreover, all our packages using this JLL use `~` in their compat ranges.
#
# Together, this allows us to increment the patch level of the JLL for minor
# tweaks. If a rebuild of the JLL is needed which keeps the upstream version
# identical but breaks ABI compatibility for any reason, we can increment the
# minor version e.g. go from 401.300.500 to 401.301.500.
#
# To package prerelease versions, we can also adjust the minor version; e.g. we may
# map a prerelease of 4.1.4 to 401.390.000.
#
# There is currently no plan to change the major version, except when upstream itself
# changes its major version. It simply seemed sensible to apply the same transformation
# to all components.
#
name = "Singular"
version = v"402.000.000"
upstream_version = v"4.2.0"

# Collection of sources required to build normaliz
sources = [
    #GitSource("https://github.com/Singular/Singular.git", "8cf4d31bb708e264c0e6082a13985538a2acd84f"),
    ArchiveSource("https://www.mathematik.uni-kl.de/ftp/pub/Math/Singular/SOURCES/$(upstream_version.major)-$(upstream_version.minor)-$(upstream_version.patch)/singular-$(upstream_version).tar.gz",
                  "5b0f6c036b4a6f58bf620204b004ec6ca3a5007acc8352fec55eade2fc9d63f6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd [Ss]ingular*
#./autogen.sh
export CPPFLAGS="-I${prefix}/include"
./configure --prefix=$prefix --host=$target --build=${MACHTYPE} \
    --with-libparse \
    --enable-shared \
    --disable-static \
    --enable-p-procs-static \
    --disable-p-procs-dynamic \
    --enable-gfanlib \
    --with-readline=no \
    --with-gmp=$prefix \
    --with-flint=$prefix \
    --without-python

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpolys", :libpolys),
    LibraryProduct("libSingular", :libsingular),
    # LibraryProduct("customstd", :customstd),
    # LibraryProduct("subsets", :subsets),
    ExecutableProduct("Singular", :Singular),
    ExecutableProduct("libparse", :libparse),
    # LibraryProduct("syzextra", :syzextra),
    # LibraryProduct("interval", :interval),
    LibraryProduct("libfactory", :libfactory),
    LibraryProduct("libsingular_resources", :libsingular_resources),
    LibraryProduct("libomalloc", :libomalloc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("cddlib_jll"),
    Dependency(PackageSpec(name="FLINT_jll", version=VersionSpec("200.700"))),
    Dependency("GMP_jll", v"6.1.2"),
    Dependency("MPFR_jll", v"4.0.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
