# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libLAS"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/libLAS/libLAS.git", "e6a1aaed412d638687b8aec44f7b12df7ca2bbbb"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libLAS/

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/comment-out-FixupOrdering.patch

if [[ "${target}" == *-mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-rename-libs.patch
elif [[ "${target}" == aarch64-linux-musl* ]] || [[ "${target}" == arm-linux-musleabihf ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/add-arch-macros.patch
fi

mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_BUILD_TYPE=Release \
-DWITH_UTILITIES=FALSE \
-DWITH_TESTS=FALSE \
-DBUILD_OSGEO4W=FALSE \
-DWITH_LASZIP=TRUE \
-DWITH_GDAL=TRUE \
-DWITH_GEOTIFF=TRUE

make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
#cmake install only grabs the .dll.a and leaves the actual .dll behind, manually move it 
mv bin/Release/*.dll ${libdir}
fi


"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


# The products that we will ensure are always built
products = [
    LibraryProduct("liblas", :liblas),
    LibraryProduct("liblas_c", :liblas_c)
    #ExecutableProduct("las2txt", :las2txt),
    #ExecutableProduct("lasinfo", :lasinfo),
    #ExecutableProduct("ts2las", :ts2las),
    #ExecutableProduct("las2col", :las2col),
    #ExecutableProduct("las2pg", :las2pg),
    #ExecutableProduct("lasblock", :lasblock),
    #ExecutableProduct("las2las", :las2las),
    #ExecutableProduct("txt2las", :txt2las),
    #ExecutableProduct("las2ogr", :las2ogr)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"; compat="=1.76.0")
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
    Dependency(PackageSpec(name="PROJ_jll", uuid="58948b4f-47e0-5654-a9ad-f609743f8632"))
    Dependency(PackageSpec(name="libgeotiff_jll", uuid="06c338fa-64ff-565b-ac2f-249532af990e"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")
