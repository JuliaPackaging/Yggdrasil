# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PDAL"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/PDAL/PDAL/releases/download/$version/PDAL-$version-src.tar.gz", "5b0b92258874ef722b5027054d64c8b318b524e7a9b2b250d0330d76e19b8618"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/PDAL-*/

if [[ "${target}" == x86_64-linux-musl ]]; then
    # Delete libexpat to prevent it from being picked up by mistake
    rm /usr/lib/libexpat.so*
    # Convince to link `pdal` to libcurl.  Honestly I don't understand why this
    # doesn't work out-of-the-box, like it does for other platforms, this is a
    # quick patch to make it work.
    atomic_patch -p1 ../patches/x86_64-linux-musl-pdal-curl.patch
fi

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/relative_path_dimbuilder.patch
# We'll build `dimbuilder` separately.
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmake-disable-dimbuilder.patch
if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-arbiter.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-charbuf.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-cmake-macros.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-cmake-patches.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-delete-japanese-unicode-test.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-dynamiclibrary.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-fileutils.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-greedyprojection.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-optech.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-pointlayout.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-portableendian.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-sbetwriter.patch
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-sparsematrix.patch
    if [[ "${nbits}" -eq 32 ]]; then
        atomic_patch -p1 ../patches/mingw-trapoline-stdcall.patch
    fi
fi

mkdir -p build/dimbuilder && cd build/dimbuilder

# Build dimbuilder with the host compiler.
(
    # For some reason, CMake seems to ignore the toolchain file, let's force the
    # compiler with the CXX environment variable
    export CXX=${HOST_CXX}
    cmake ../../dimbuilder -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
        -DNLOHMANN_INCLUDE_DIR="$(realpath ../../vendor/nlohmann)" \
        -DCMAKE_BUILD_TYPE=Release
    ninja -j${nproc}
    mkdir -p ../bin
    mv dimbuilder ../bin/.
)

cd ..
cmake .. -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_LIBRARY_PATH:FILEPATH="${libdir}" \
    -DCMAKE_INCLUDE_PATH:FILEPATH="${includedir}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_PLUGIN_I3S=OFF \
    -DBUILD_PLUGIN_NITF=OFF \
    -DBUILD_PLUGIN_TILEDB=OFF \
    -DBUILD_PLUGIN_ICEBRIDGE=OFF \
    -DBUILD_PLUGIN_HDF=OFF \
    -DBUILD_PLUGIN_PGPOINTCLOUD=OFF \
    -DBUILD_PLUGIN_E57=OFF \
    -DBUILD_PGPOINTCLOUD_TESTS=OFF \
    -DWITH_LAZPERF=OFF \
    -DBUILD_PGPOINTCLOUD_TESTS=OFF \
    -DWITH_LASZIP=ON \
    -DWITH_ZSTD=ON \
    -DWITH_ZLIB=ON \
    -DWITH_TESTS=OFF

ninja -j${nproc}
ninja install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = [
#    Platform("x86_64", "linux"; libc = "glibc")
#]

platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("libpdal_util", :libpdal_util),
    LibraryProduct(["libpdal_base", "libpdalcpp"], :libpdal_base),
    LibraryProduct("libpdal_plugin_kernel_fauxplugin", :libpdal_plugin_kernel_fauxplugin),
    ExecutableProduct("pdal", :pdal),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    Dependency(PackageSpec(name="libgeotiff_jll", uuid="06c338fa-64ff-565b-ac2f-249532af990e"))
    Dependency(PackageSpec(name="LASzip_jll", uuid="8372b9c3-1e34-5cc3-bfab-1a98e101de11"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# PDAL GitHub CI scripts currently run on GCC 7.5, so we'll match them in major version at least
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.6")
