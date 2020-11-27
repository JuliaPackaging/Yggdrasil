# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GAP_lib"
version = v"4.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gap-system/gap.git", "9ec24ed6221b2429bc0a79457814c1b1bda09df4"),
#    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(version)/gap-$(version)-core.tar.bz2",
#                  "6637f66409bc91af21eaa38368153270b71b13b55b75cc1550ed867c629901d1"),
    ArchiveSource("https://github.com/gap-system/gap/releases/download/v$(version)/packages-required-v$(version).tar.gz",
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
