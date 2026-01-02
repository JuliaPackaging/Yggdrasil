#=
BINARYBUILDER_RUNNER=privileged julia build_tarballs.jl --verbose --debug
=#

using BinaryBuilder
using Pkg
using Pkg: PackageSpec

version = v"2.6.0" # libIGL version, see below:

sources = [
    # 2.6.0 stable release
    GitSource(
        "https://github.com/libigl/libigl.git",
        "40e7900ccbd767f1f360e0eb10f0f1a6432e0993"),
]

script = raw"""
cd $WORKSPACE/srcdir/libigl

apk del cmake

mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DLIBIGL_USE_STATIC_LIBRARY=ON \
    -DLIBIGL_BUILD_TESTS=OFF \
    -DLIBIGL_BUILD_TUTORIALS=OFF \
    -DLIBIGL_EMBREE=OFF \
    -DLIBIGL_GLFW=OFF \
    -DLIBIGL_IMGUI=OFF \
    -DLIBIGL_OPENGL=OFF \
    -DLIBIGL_IMGUI=OFF \
    -DLIBIGL_COPYLEFT_CGAL=ON \
    -DLIBIGL_PNG=OFF \
    -DLIBIGL_RESTRICTED_MATLAB=OFF \
    -DLIBIGL_RESTRICTED_MOSEK=OFF \
    ..

make -j${nproc}
make install
cd $WORKSPACE/srcdir/libigl
install_license LICENSE.GPL LICENSE.MPL2
"""

products = [
	LibraryProduct("libigl", :libigl)
]

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("GMP_jll"; compat="6.2.0"),
    Dependency("MPFR_jll"; compat="4.1.0"),
    BuildDependency("Eigen_jll"),
    BuildDependency("CGAL_jll"),
    Dependency("ICU_jll"; compat="69.1"),
    HostBuildDependency(PackageSpec(; name="CMake_jll", version = "3.28.1"))
]

build_tarballs(ARGS, "libigl", version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"9", julia_compat="1.6"
)
