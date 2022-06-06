using BinaryBuilder, Pkg

name = "libgeotiff"
version = v"1.7.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OSGeo/libgeotiff/releases/download/$version/libgeotiff-$version.tar.gz",
                  "05ab1347aaa471fc97347d8d4269ff0c00f30fa666d956baba37948ec87e55d6"),
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libgeotiff-*/

mkdir build && cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      ..

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libgeotiff", :libgeotiff),
    ExecutableProduct("makegeo", :makegeo),
    ExecutableProduct("geotifcp", :geotifcp),
    ExecutableProduct("listgeo", :listgeo),
    ExecutableProduct("applygeo", :applygeo),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("PROJ_jll"; compat="~900.0"),
    Dependency("Libtiff_jll"; compat="4.3"),
    Dependency("LibCURL_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
