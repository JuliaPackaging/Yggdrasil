# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

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

name = "GAP_lib"
version = v"400.1100.0"
upstream_version = v"4.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gap-system/gap.git", "7a2dfbec79d3d20a4ac4d5f174eaf35aa34387d7"),
#    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(upstream_version)/gap-$(upstream_version)-core.tar.bz2",
#                  "6637f66409bc91af21eaa38368153270b71b13b55b75cc1550ed867c629901d1"),
    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(upstream_version)/packages-required-v$(upstream_version).tar.gz",
                  "29ab6e2752f39d22e3f0a19e5bcbfec1710993b4cfd52337a0ca10fda6a76537";
                  unpack_target="pkg"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/gap*

mv ../pkg .
find pkg -name '._*' -exec rm \{\} \; # unwanted files

# run autogen.sh if compiling from it source and/or if configure was patched
./autogen.sh

# compile a native version of GAP so we can use it to generate the manual
# (the manual is only in FULL gap release tarballs, not in the -core tarball
# nor in git snapshots)
mkdir native-build
cd native-build
#apk add gmp-dev zlib-dev
../configure --build=${MACHTYPE} --host=${MACHTYPE} CC=${CC_BUILD} CXX=${CXX_BUILD} --with-zlib=${prefix} --with-gmp=${prefix}
make -j${nproc}
make html   # build the manual (only HTML and txt; for PDF we'd need LaTeX)
cd ..

# remove the native build, it has done its job
rm -rf native-build

# the license
install_license LICENSE

# "install" most of the files
rm -rf autom4te.cache dev etc extern hpcgap/extern pkg
mkdir -p ${prefix}/share/gap/
mv * ${prefix}/share/gap/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [AnyPlatform()]

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("Zlib_jll"),
    BuildDependency("GMP_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
