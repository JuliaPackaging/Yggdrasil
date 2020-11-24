# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libfreenect"
version = v"0.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/OpenKinect/libfreenect.git", "edad69caabe662e7996db9425c8b5c568efa275d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libfreenect/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_CPP=OFF -DBUILD_EXAMPLES=OFF -DBUILD_FAKENECT=OFF -DBUILD_REDIST_PACKAGE=OFF ..
make
make install
install_license ../APACHE20 ../GPL2
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct("libfreenect_sync", :libfreenect_sync),
    LibraryProduct("libfreenect", :lifreenect)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libusb_jll", uuid="a877fdc9-fe69-5ed6-b93d-11ecd0dc2d49"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
