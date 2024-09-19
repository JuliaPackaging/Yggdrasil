#=
BINARYBUILDER_RUNNER=privileged julia build_tarballs.jl --verbose --debug
=#

using BinaryBuilder
using Pkg

version = v"2.4.0" # libIGL version, see below:

sources = [
    # 2.5.0 stable release
    GitSource(
        "https://github.com/libigl/libigl.git",
        "66b3ef2253e765d0ce0db74cec91bd706e5ba176"),
]

script = raw"""
cd $WORKSPACE/srcdir/libigl
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
install_license /usr/share/licenses/GPL3
"""

products = [
	LibraryProduct("libigl", :libigl)
]

platforms = expand_cxxstring_abis(supported_platforms())

dependencies = [
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    BuildDependency("Eigen_jll"),
    BuildDependency("CGAL_jll"),
    Dependency("ICU_jll")
]

build_tarballs(ARGS, "libigl", version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"9", julia_compat="1.6"
)
