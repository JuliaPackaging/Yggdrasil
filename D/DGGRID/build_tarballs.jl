using BinaryBuilder, Pkg

name = "DGGRID"
version_string = "9.1"
# upstream versions sort as decimals (8.36 < 8.4 < 8.41) -> 9.1 maps to 9.10
version = v"9.10.0"

sources = [
    GitSource("https://github.com/sahrk/DGGRID.git",
              "4f8bf6150ae0e77fd669c8ed8a5e1cffa9664b36"; tag="v$(version_string)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/DGGRID
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_H3=OFF \
    -DCMAKE_REQUIRE_FIND_PACKAGE_GDAL=ON
if [[ "${target}" == x86_64-linux-musl ]]; then
    # Remove libexpat to avoid it being picked up by mistake
    rm -v /usr/lib/libexpat.so*
fi
cmake --build build --parallel ${nproc} --target dggrid
install -Dvm 755 "build/src/apps/dggrid/dggrid${exeext}" "${bindir}/dggrid${exeext}"
install_license LICENSE
install_license LICENSE.H3
install -Dvm 644 src/lib/proj4lib/LICENSE "${prefix}/share/licenses/${SRC_NAME}/LICENSE.proj4lib"
install -Dvm 644 src/lib/shapelib/LICENSE "${prefix}/share/licenses/${SRC_NAME}/LICENSE.shapelib"
"""

platforms = supported_platforms()
# GDAL_jll can resolve to its OpenMPI build here, and OpenMPI_jll has none
filter!(p -> !(Sys.islinux(p) && (arch(p) in ("i686", "armv7l") || (arch(p) == "armv6l" && libc(p) == "musl"))), platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("dggrid", :dggrid),
]

dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"); compat="305.1300.301"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", julia_compat="1.9")
