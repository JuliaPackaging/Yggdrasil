# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PDAL"
version = v"2.6.3"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/PDAL/PDAL.git", "d37b077053116f4b76d360d379dbcaf890fd4a39"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/PDAL*

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK which supports `std::filesystem`, taken from HELICS build_tarballs.jl
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
    export MACOSX_DEPLOYMENT_TARGET=10.15
fi

mkdir -p build/dimbuilder && cd build/dimbuilder

# Build dimbuilder with the host compiler before main library.
#see also https://github.com/conda-forge/pdal-feedstock/blob/main/recipe/build.sh
(
    cmake ../../dimbuilder -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_HOST_TOOLCHAIN} \
        -DNLOHMANN_INCLUDE_DIR="$(realpath ../../vendor/nlohmann)" \
        -DUTFCPP_INCLUDE_DIR="$(realpath ../../vendor/utfcpp/source)" \
        -DCMAKE_BUILD_TYPE=Release
    ninja -j${nproc}
)

#make sure we're back in source dir
cd $WORKSPACE/srcdir/PDAL*
cd build

cmake .. -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_LIBRARY_PATH:FILEPATH="${libdir}" \
    -DCMAKE_INCLUDE_PATH:FILEPATH="${includedir}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DDIMBUILDER_EXECUTABLE="$WORKSPACE/srcdir/PDAL/build/dimbuilder/dimbuilder" \
    -DBUILD_PLUGIN_I3S=OFF \
    -DBUILD_PLUGIN_NITF=OFF \
    -DBUILD_PLUGIN_TILEDB=OFF \
    -DBUILD_PLUGIN_ICEBRIDGE=OFF \
    -DBUILD_PLUGIN_HDF=OFF \
    -DBUILD_PLUGIN_PGPOINTCLOUD=OFF \
    -DBUILD_PLUGIN_E57=OFF \
    -DBUILD_PGPOINTCLOUD_TESTS=OFF \
    -DBUILD_PGPOINTCLOUD_TESTS=OFF \
    -DWITH_ZSTD=ON \
    -DWITH_ZLIB=ON \
    -DWITH_TESTS=OFF

ninja -j${nproc}
ninja install
"""

platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct(["libpdal_base", "libpdalcpp"], :libpdal_base),
    LibraryProduct("libpdal_plugin_kernel_fauxplugin", :libpdal_plugin_kernel_fauxplugin),
    ExecutableProduct("pdal", :pdal),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c")),
    Dependency(PackageSpec(name="libgeotiff_jll", uuid="06c338fa-64ff-565b-ac2f-249532af990e")),
    # From GDAL recipe, for 32-bit platforms, when we need to link to OpenMP we need version 4,
    # because version 5 dropped support for these architectures
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.6"); platforms=filter(p -> nbits(p)==32, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
# we require a compiler that supports C++ 17 and <filesystem>
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"9", julia_compat="1.6")
