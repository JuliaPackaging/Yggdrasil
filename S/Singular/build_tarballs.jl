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

upstream_version = v"4.4.0-7" # 4.4.0p7
version_offset = v"0.0.8"

version = VersionNumber(upstream_version.major * 100 + upstream_version.minor + version_offset.major,
                        upstream_version.patch * 100 + version_offset.minor,
                        Int(upstream_version.prerelease[1]) * 100 + version_offset.patch)

# Collection of sources required to build normaliz
sources = [
    GitSource("https://github.com/Singular/Singular.git", "b3ba3db6b5a761767722d2e7bd42b5771924a5ec"),
    #ArchiveSource("https://www.mathematik.uni-kl.de/ftp/pub/Math/Singular/SOURCES/$(upstream_version.major)-$(upstream_version.minor)-$(upstream_version.patch)/singular-$(upstream_version).tar.gz",
    #              "5b0f6c036b4a6f58bf620204b004ec6ca3a5007acc8352fec55eade2fc9d63f6"),
    #DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd [Ss]ingular*

#for f in ${WORKSPACE}/srcdir/patches/*.patch; do
#    atomic_patch -p1 ${f}
#done

./autogen.sh
export CPPFLAGS="-I${prefix}/include"

# lld doesn't support -r and -keep_private_externs which the Singular build uses
# switch back to ld on macos to avoid errors:
if [[ "${target}" == *apple* ]]; then
  export LDFLAGS="-fuse-ld=ld"
fi

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
    --without-python \
    --with-builtinmodules=gfanlib,syzextra,customstd,interval,subsets,loctriv,gitfan,freealgebra \
    --disable-partialgb-module \
    --disable-polymake-module \
    --disable-pyobject-module \
    --disable-singmathic-module \
    --disable-systhreads-module \
    --disable-cohomo-module \
    --disable-machinelearning-module \
    --disable-sispasm-module

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(!Sys.iswindows, platforms)
filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)
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
    Dependency(PackageSpec(name="FLINT_jll"), compat = "~300.100.300"),
    Dependency("GMP_jll", v"6.2.0"),
    Dependency("MPFR_jll", v"4.1.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version=v"6", julia_compat = "1.6")
