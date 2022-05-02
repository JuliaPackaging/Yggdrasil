# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bullet_Physics_SDK"
version = v"3.22.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/bulletphysics/bullet3/archive/refs/tags/3.22b.tar.gz",
                  "c6cd89ecbc4bd73fee64723c831c1578daab056d88774755a6f56afc6f417b2b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bullet*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD="11" \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_PYBULLET=OFF \
    -DBUILD_PYBULLET_NUMPY=OFF \
    -DBUILD_UNIT_TESTS=OFF \
    -DBUILD_CPU_DEMOS=OFF \
    -DBUILD_OPENGL3_DEMOS=OFF \
    -DBUILD_BULLET2_DEMOS=OFF \
    -DBT_USE_EGL=OFF \
    -DUSE_DOUBLE_PRECISION=OFF \
    -DBUILD_EXTRAS=OFF \
    -S .. \
    -B .
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
        FileProduct("lib/libBullet3OpenCL_clew.a", :libBullet3OpenCL_clew),
        FileProduct("lib/libBullet2FileLoader.a", :libBullet2FileLoader),
        FileProduct("lib/libBullet3Dynamics.a", :libBullet3Dynamics),
        FileProduct("lib/libBullet3Collision.a", :libBullet3Collision),
        FileProduct("lib/libBullet3Geometry.a", :libBullet3Geometry),
        FileProduct("lib/libBulletInverseDynamics.a", :libBulletInverseDynamics),
        FileProduct("lib/libBulletSoftBody.a", :libBulletSoftBody),
        FileProduct("lib/libBulletCollision.a", :libBulletCollision),
        FileProduct("lib/libBulletDynamics.a", :libBulletDynamics),
        FileProduct("lib/libLinearMath.a", :libLinearMath),
        FileProduct("lib/libBullet3Common.a", :libBullet3Common),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
