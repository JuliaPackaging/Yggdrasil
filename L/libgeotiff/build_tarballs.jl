using BinaryBuilder, Pkg

name = "libgeotiff"
upstream_version = v"1.7.3"
version_offset = v"0.1.0"
version = VersionNumber(upstream_version.major * 100 + version_offset.major,
                        upstream_version.minor * 100 + version_offset.minor,
                        upstream_version.patch * 100 + version_offset.patch)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OSGeo/libgeotiff/releases/download/$upstream_version/libgeotiff-$upstream_version.tar.gz",
                  "ba23a3a35980ed3de916e125c739251f8e3266be07540200125a307d7cf5a704"),
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
    Dependency("PROJ_jll"; compat="901.300.0"),
    Dependency("Libtiff_jll"; compat="4.5.1"),
    Dependency("LibCURL_jll"; compat="7.73,8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

# Build trigger: 1
