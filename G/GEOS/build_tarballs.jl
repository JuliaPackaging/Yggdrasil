# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "GEOS"
version = v"3.14.0"

# Collection of sources required to build GEOS
sources = [
    ArchiveSource("http://download.osgeo.org/geos/geos-$version.tar.bz2",
                  "fe85286b1977121894794b36a7464d05049361bedabf972e70d8f9bf1e3ce928"),
    FileSource("https://github.com/phracker/MacOSX-SDKs/releases/download/11.3/MacOSX11.3.sdk.tar.xz",
               "cd4f08a75577145b8f05245a2975f7c81401d75e9535dcffbb879ee1deefcbf4"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/geos-*/

# We need a newer C++ library
if [[ "${target}" == *-apple-darwin* ]]; then
    rm -rf /opt/${target}/${target}/sys-root/System
    rm -rf /opt/${target}/${target}/sys-root/usr/include/libxml2/libxml
    tar --extract --file=${WORKSPACE}/srcdir/MacOSX11.3.sdk.tar.xz --directory="/opt/${target}/${target}/sys-root/." --strip-components=1 MacOSX11.3.sdk/System MacOSX11.3.sdk/usr
    export MACOSX_DEPLOYMENT_TARGET=11.3
fi

# Reported as <https://github.com/libgeos/geos/issues/1302>
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/unordered_map.patch

CMAKE_FLAGS=()
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix})
CMAKE_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN})
CMAKE_FLAGS+=(-DLLVM_HOST_TRIPLE=${MACHTYPE})
CMAKE_FLAGS+=(-DCMAKE_BUILD_TYPE=Release)
CMAKE_FLAGS+=(-DBUILD_TESTING=OFF)
CMAKE_FLAGS+=(-S.) # source

# arm complains about duplicate symbols unless we disable inlining
if [[ ${target} == arm* ]]; then
    CMAKE_FLAGS+=(-DDISABLE_GEOS_INLINE=true)
fi

cmake ${CMAKE_FLAGS[@]}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeos_c", :libgeos),
    LibraryProduct(["libgeos", "libgeos-$(version.major)-$(version.minor)"], :libgeos_cpp),
    ExecutableProduct("geosop", :geosop),
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
# We need at least GCC 7 for newer C++ features
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"7")
