using BinaryBuilder, Pkg

name = "libsparseir"
version = v"0.6.0"

# Collection of sources required to complete build
sources = [
    # libsparseir v0.6.0
    GitSource(
        "https://github.com/SpM-lab/libsparseir.git",
        "ae7d8330b7e452cb31b5ded76c5a656f336906a4",
    ),
    # libxprec v0.7.0
    GitSource(
        "https://github.com/tuwien-cms/libxprec.git",
        "d35f3fa9a962d3f96a1eef63132030fd869c183a"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/libsparseir/
install_license LICENSE
if [[ "${target}" == *mingw* ]]; then
  LBT="${libdir}/libblastrampoline-5.dll"
else
  LBT="-lblastrampoline"
fi

${CXX} -O3 -fPIC -shared -std=c++11 -I${includedir}/eigen3/ -Iinclude -I../libxprec/include ${LBT} src/*.cpp -o ${libdir}/libsparseir.${dlext}
cp include/sparseir/sparseir.h include/sparseir/spir_status.h include/sparseir/version.h ${includedir}
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libsparseir", :libsparseir),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency("Eigen_jll"),
    Dependency(PackageSpec(name="libblastrampoline_jll", uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), compat="5.4.0"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.10", compilers=[:c, :cxx], preferred_gcc_version=v"8")
