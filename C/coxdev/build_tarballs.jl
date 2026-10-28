using BinaryBuilder, Pkg

name = "coxdev"
version = v"0.5.0"  

sources = [
    GitSource("https://github.com/jonathan-taylor/coxdev.git",
              "d10150baa559ffb088aff2ef2e1427ebd697f32c";
              tag="v$(version)")
]

script = raw"""
cd ${WORKSPACE}/srcdir/coxdev/cpp/capi
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DEIGEN_INCLUDE_DIR=${includedir}/eigen3 \
    -DCOXDEV_C_TESTS=OFF
cmake --build build --parallel ${nproc}
install -Dvm 755 build/libcoxdev_c.${dlext} ${libdir}/libcoxdev_c.${dlext}
install -Dvm 644 ../include/coxdev_c_api.h ${includedir}/coxdev_c_api.h
install_license ${WORKSPACE}/srcdir/coxdev/LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libcoxdev_c", :libcoxdev_c),
]

dependencies = [
    BuildDependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70", version=v"3.4.0")),
]

# C++17 for coxdev; GCC 8 is the first with full C++17 support
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.9", preferred_gcc_version=v"8")
