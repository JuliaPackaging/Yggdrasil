using BinaryBuilder, Pkg

name = "libigl"
version = v"2.6.0"

sources = [
    # 2.6.0 stable release
    GitSource(
        "https://github.com/libigl/libigl.git",
        "40e7900ccbd767f1f360e0eb10f0f1a6432e0993"),
]

script = raw"""
cd $WORKSPACE/srcdir/libigl

apk del cmake

# Fix gettimeofday declaration issue on macOS by defining _DEFAULT_SOURCE
# This is needed for GLFW's posix_time.c which uses gettimeofday
if [[ "${target}" == *darwin* ]]; then
    EXTRA_CMAKE_FLAGS="-DCMAKE_C_FLAGS=-D_DEFAULT_SOURCE"
else
    EXTRA_CMAKE_FLAGS=""
fi

mkdir -p build
cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ${EXTRA_CMAKE_FLAGS} \
    -DBLA_VENDOR=OpenBLAS \
    -DLIBIGL_USE_STATIC_LIBRARY=ON \
    -DLIBIGL_BUILD_TESTS=OFF \
    -DLIBIGL_BUILD_TUTORIALS=OFF \
    -DLIBIGL_EMBREE=OFF \
    -DLIBIGL_GLFW=ON \
    -DLIBIGL_IMGUI=ON \
    -DLIBIGL_OPENGL=ON \
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
    FileProduct("lib/libigl.a", :libigl_a)
]

platforms = expand_cxxstring_abis(supported_platforms())

# Filter platforms with known issues
# 32-bit architectures have compatibility issues with CGAL/libigl
filter!(p -> nbits(p) ≠ 32, platforms)
# PowerPC is not well supported
filter!(p -> arch(p) != "powerpc64le", platforms)
# Windows has template instantiation issues with size_t (unsigned long long vs unsigned long)
filter!(p -> !Sys.iswindows(p), platforms)
# FreeBSD has build issues
filter!(p -> !Sys.isfreebsd(p), platforms)
# macOS x86_64 has build issues (aarch64 works)
filter!(p -> !(Sys.isapple(p) && arch(p) == "x86_64"), platforms)

# Platform-specific dependencies for OpenGL and GLFW
x11_platforms = filter(p -> Sys.islinux(p), platforms)

dependencies = [
    Dependency("GMP_jll"),
    Dependency("MPFR_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("ICU_jll"),
    BuildDependency("Eigen_jll"),
    BuildDependency("CGAL_jll"),
    HostBuildDependency("CMake_jll"),
    Dependency("GLFW_jll"),
    Dependency("Libglvnd_jll"; platforms=x11_platforms),
    # X11 dependencies for GLFW on Linux
    BuildDependency("Xorg_xorgproto_jll"; platforms=x11_platforms),
]

build_tarballs(ARGS, name, version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version=v"8", julia_compat="1.6"
)
