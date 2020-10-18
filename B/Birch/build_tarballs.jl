# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Birch"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lawmurray/Birch.git", "0f1461151837d3012b3aedc8121955752a58995e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# add FreeBSD support
export CPPFLAGS="-I${prefix}/include"
cd ${WORKSPACE}/srcdir/Birch/
atomic_patch -p1 ${WORKSPACE}/srcdir/freebsd.patch

# install the driver
cd ${WORKSPACE}/srcdir/Birch/driver/
#atomic_patch -p1 ${WORKSPACE}/srcdir/getline.patch
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install

# install LibBirch
cd ${WORKSPACE}/srcdir/Birch/libbirch/
autoreconf -vi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-debug --enable-release
make -j${nproc}
make install

# compile the driver for host
mkdir -p ${WORKSPACE}/srcdir/build_host

# add libraries for building birch on host
apk add boost-dev yaml-dev

# patch glob flag (not supported by musl)
cd ${WORKSPACE}/srcdir/Birch/driver/
if [[ "${MACHTYPE}" == *-musl* ]]; then
  atomic_patch -p1 ${WORKSPACE}/srcdir/glob_nomagic.patch
fi

# build an install driver on host system
bb_target=${MACHTYPE} CXX=${HOSTCXX} CPPFLAGS=-I/usr/include LDFLAGS=-L/usr/lib ./configure --prefix=${WORKSPACE}/srcdir/build_host --build=${MACHTYPE} --host=${MACHTYPE}
make clean
make -j${nproc}
make install

# install the standard library
cd ${WORKSPACE}/srcdir/Birch/libraries/Standard/
export BIRCH_PREFIX=${WORKSPACE}/srcdir/build_host
export PATH=${WORKSPACE}/srcdir/build_host/bin:$PATH
birch bootstrap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-debug --enable-release
make -j${nproc}
make install

# install LICENSE
install_license ${WORKSPACE}/srcdir/Birch/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# GLOB_NOMAGIC is not supported by musl
filter!(p -> libc(p) != "musl", platforms)

# Native support for Windows is not yet provided
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("birch", :birch),
    LibraryProduct("libbirch", :libbirch),
    LibraryProduct("libbirch-debug", :libbirch_debug),
    LibraryProduct("libbirch-standard", :libbirch_standard),
    LibraryProduct("libbirch-standard-debug", :libbirch_standard_debug),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("boost_jll"),
    Dependency("Eigen_jll"),
    Dependency("LibYAML_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5")
