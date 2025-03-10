using BinaryBuilder, Pkg

name = "blockSQP"
version = v"0.0.1"
sources = [
    GitSource("https://github.com/djanka2/blockSQP.git", "da05d3957b93bd55b9a7f08c859d302851056a6d"),
    GitSource("https://github.com/mathopt/blockSQPWrapper.git", "8d796eda6ceb986c2e04888176c6cb292b94011e"),
    DirectorySource("./bundled")
]

include("../../L/libjulia/common.jl")

script = raw"
apk del cmake
cd ${WORKSPACE}/srcdir
mv blockSQPWrapper/CMakeLists.txt blockSQP/CMakeLists.txt
mv blockSQPWrapper/blockSQP_julia.cpp blockSQP/src/blockSQP_julia.cpp
cd blockSQP
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
mkdir build && cd build

cmake \
    -DJulia_PREFIX=$prefix \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_PREFIX_PATH=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    ..

make
make install
install_license ${WORKSPACE}/srcdir/blockSQP/LICENSE
"

platforms = vcat(libjulia_platforms.(julia_versions[julia_versions .>= v"1.10.0"])...)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(p -> !(libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(p -> !(os(p) == "freebsd"), platforms)


dependencies = [
    Dependency("qpOASES_jll"; compat="3.2.1"),
    Dependency("libcxxwrap_julia_jll"; compat="0.13.4"),
    HostBuildDependency(PackageSpec(; name = "CMake_jll")),
    BuildDependency("libjulia_jll")
]

products = [
    LibraryProduct("libblockSQP", :libblockSQP)
    LibraryProduct("libblockSQP_wrapper", :libblockSQP_wrapper)
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        julia_compat="1.10", preferred_gcc_version=v"9")
