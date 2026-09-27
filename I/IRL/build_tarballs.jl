using BinaryBuilder, Pkg

name    = "IRL"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/robert-chiodi/interface-reconstruction-library.git",
              "062aa7659a6a46e3ae13de6be8b3fa787902b8c6"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/interface-reconstruction-library

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/abseil-static-pic.patch

mkdir build && cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DEigen3_DIR=${prefix}/share/eigen3/cmake

cmake --build . --target irl_c -j${nproc}

mkdir -p ${libdir} ${includedir}
install -Dvm755 libirl.${dlext} ${libdir}/libirl.${dlext}
install -Dvm755 libirl_c.${dlext} ${libdir}/libirl_c.${dlext}

cp -rv ../irl ${includedir}/
find ${includedir}/irl -type f ! -name '*.h' ! -name '*.tpp' -print -delete
"""

platforms = supported_platforms()
platforms = filter(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libirl_c", :libirl_c),
    LibraryProduct("libirl",   :libirl),
]

dependencies = [
    BuildDependency(PackageSpec(name = "Eigen_jll")),
    Dependency(PackageSpec(name = "CompilerSupportLibraries_jll")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version = v"9", julia_compat = "1.6")
