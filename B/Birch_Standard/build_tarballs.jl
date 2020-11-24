# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Birch_Standard"
# Birch's version is `(git describe --long || echo) | sed -E 's/v([0-9]+)-([0-9]+)-g[0-9a-f]+/\1.\2/'`
# (see https://github.com/JuliaPackaging/Yggdrasil/pull/2156#discussion_r528224861)
version = v"1.75"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/lawmurray/Birch.git", "a533990b59b04ef4cd20f8d4fe91c4a220df1cfa"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
# add libraries for building birch on host
apk add boost-dev yaml-dev

# build and install driver on host system
cd ${WORKSPACE}/srcdir/Birch/driver/
mkdir -p ${WORKSPACE}/srcdir/build_host
autoreconf -vi
CXX=${HOSTCXX} CPPFLAGS=-I/usr/include LDFLAGS=-L/usr/lib ./configure --prefix=${WORKSPACE}/srcdir/build_host --build=${MACHTYPE} --host=${MACHTYPE}
make clean
make -j${nproc}
make install

# build and install the standard library
cd ${WORKSPACE}/srcdir/Birch/libraries/Standard/
export BIRCH_PREFIX=${WORKSPACE}/srcdir/build_host
export PATH=${WORKSPACE}/srcdir/build_host/bin:$PATH
# musl c library does not define stdin, stdout, and stderr macros as objects
if [[ "${target}" == *-musl* ]]; then
  atomic_patch -p3 ${WORKSPACE}/srcdir/stdio.patch
fi
birch bootstrap
CPPFLAGS="-I${prefix}/include" ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-debug --enable-release
make -j${nproc}
make install

# install license
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# Native support for Windows is not yet provided
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbirch-standard", :libbirch_standard),
    LibraryProduct("libbirch-standard-debug", :libbirch_standard_debug),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("Eigen_jll"),
    Dependency(PackageSpec(name = "LibBirch_jll", version = version)),
    Dependency("LibYAML_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               preferred_gcc_version=v"5")
