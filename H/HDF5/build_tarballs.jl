using BinaryBuilder

# Collection of sources required to build HDF5
name = "HDF5"
version = v"1.12.0"

sources = [
    GitSource("https://github.com/HDFGroup/hdf5.git",
              "eac2cd54e209cfa9556174f3fc1a592533aa64ad"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/hdf5/
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DHDF5_BUILD_CPP_LIB=OFF \
    -DONLY_SHARED_LIBS=ON \
    -DHDF5_BUILD_HL_LIB=ON \
    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
    -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
    -DHDF5_ENABLE_SZIP_ENCODING=OFF \
    -DBUILD_TESTING=OFF \
    -DCMAKE_CROSSCOMPILING=OFF
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/hdf5/COPYING*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhdf5", :libhdf5),
    LibraryProduct("libhdf5_hl", :libhdf5_hl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Zlib_jll"),
    Dependency("OpenSSL_jll"; compat="1.1.10"),
    Dependency("LibCURL_jll"; compat="7.73.0"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
