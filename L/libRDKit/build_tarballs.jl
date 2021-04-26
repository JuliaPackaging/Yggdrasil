using BinaryBuilder, Pkg

julia_version = v"1.6.0"

name = "libRDKit"
version = v"2021.09.1pre"

sources = [
    GitSource("https://github.com/rdkit/rdkit.git", "af3bb3e78b24ed8d92211d9c047ddbcf5c04afc8"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/rdkit
mkdir build
cd build
cmake \
-DCMAKE_BUILD_TYPE=Release \
-DRDK_INSTALL_INTREE=OFF \
-DRDK_BUILD_INCHI_SUPPORT=ON \
-DRDK_BUILD_PYTHON_WRAPPERS=OFF \
-DRDK_BUILD_CFFI_LIB=ON \
-DRDK_BUILD_FREETYPE_SUPPORT=ON \
-DRDK_BUILD_CPP_TESTS=OFF \
-RDK_BUILD_SLN_SUPPORT=OFF \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
-DCMAKE_PREFIX_PATH=${prefix} \
..
make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("aarch64", "linux"),
    Platform("x86_64", "macos"),
    # Platform("aarch64", "macos"),
]

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libRDKitSmilesParse", :libRDKitSmilesParse),
    LibraryProduct("libRDKitRDGeometryLib", :libRDKitRDGeometryLib),
    LibraryProduct("libRDKitRDGeneral", :libRDKitRDGeneral),
    LibraryProduct("libRDKitSubstructMatch", :libRDKitSubstructMatch),
    LibraryProduct("libRDKitSubgraphs", :libRDKitSubgraphs),
    LibraryProduct("libRDKitGraphMol", :libRDKitGraphMol),
    LibraryProduct("libRDKitDistGeometry", :libRDKitDistGeometry),
    LibraryProduct("libRDKitDistGeomHelpers", :libRDKitDistGeomHelpers),
    LibraryProduct("libRDKitMolAlign", :libRDKitMolAlign),
    LibraryProduct("libRDKitOptimizer", :libRDKitOptimizer),
    LibraryProduct("libRDKitForceField", :libRDKitForceField),
    LibraryProduct("libRDKitForceFieldHelpers", :libRDKitForceFieldHelpers),
    LibraryProduct("libRDKitAlignment", :libRDKitAlignment),
    LibraryProduct("libRDKitMolTransforms", :libRDKitMolTransforms),
    LibraryProduct("libRDKitEigenSolvers", :libRDKitEigenSolvers),
    LibraryProduct("libRDKitAbbreviations", :libRDKitAbbreviations),
    LibraryProduct("libRDKitCIPLabeler", :libRDKitCIPLabeler),
    LibraryProduct("libRDKitCatalogs", :libRDKitCatalogs),
    LibraryProduct("libRDKitChemTransforms", :libRDKitChemTransforms),
    LibraryProduct("libRDKitChemicalFeatures", :libRDKitChemicalFeatures),
    LibraryProduct("libRDKitDataStructs", :libRDKitDataStructs),
    LibraryProduct("libRDKitFilterCatalog", :libRDKitFilterCatalog),
    LibraryProduct("libRDKitFingerprints", :libRDKitFingerprints),
    LibraryProduct("libRDKitFragCatalog", :libRDKitFragCatalog),
    LibraryProduct("libRDKitInfoTheory", :libRDKitInfoTheory),
    LibraryProduct("libRDKitMolCatalog", :libRDKitMolCatalog),
    LibraryProduct("libRDKitMolChemicalFeatures", :libRDKitMolChemicalFeatures),
    LibraryProduct("libRDKitMolInterchange", :libRDKitMolInterchange),
    LibraryProduct("libRDKitO3AAlign", :libRDKitO3AAlign),
    LibraryProduct("libRDKitPartialCharges", :libRDKitPartialCharges),
    LibraryProduct("libRDKitReducedGraphs", :libRDKitReducedGraphs),
    LibraryProduct("libRDKitRingDecomposerLib", :libRDKitRingDecomposerLib),
    LibraryProduct("libRDKitShapeHelpers", :libRDKitShapeHelpers),
    LibraryProduct("libRDKitSimDivPickers", :libRDKitSimDivPickers),
    LibraryProduct("libRDKitTrajectory", :libRDKitTrajectory),
    LibraryProduct("libRDKitcoordgen", :libRDKitcoordgen),
    LibraryProduct("libRDKitga", :libRDKitga),
    LibraryProduct("libRDKithc", :libRDKithc),
    LibraryProduct("libRDKitInchi", :libRDKitInchi),
    LibraryProduct("librdkitcffi", :librdkitcffi),
    # LibraryProduct("libRDKitChemReactions", :libRDKitChemReactions),
    # LibraryProduct("libRDKitFileParsers", :libRDKitFileParsers),
    # LibraryProduct("libRDKitDeprotect", :libRDKitDeprotect),
    # LibraryProduct("libRDKitDescriptors", :libRDKitDescriptors),
    # LibraryProduct("libRDKitFMCS", :libRDKitFMCS),
    # LibraryProduct("libRDKitMMPA", :libRDKitMMPA),
    # LibraryProduct("libRDKitMolEnumerator", :libRDKitMolEnumerator),
    # LibraryProduct("libRDKitMolHash", :libRDKitMolHash),
    # LibraryProduct("libRDKitMolStandardize", :libRDKitMolStandardize),
    # LibraryProduct("libRDKitRDStreams", :libRDKitRDStreams),
    # LibraryProduct("libRDKitRGroupDecomposition", :libRDKitRGroupDecomposition),
    # LibraryProduct("libRDKitScaffoldNetwork", :libRDKitScaffoldNetwork),
    # LibraryProduct("libRDKitSubstructLibrary", :libRDKitSubstructLibrary),
    # LibraryProduct("libRDKitTautomerQuery", :libRDKitTautomerQuery),
    # LibraryProduct("libRDKitmaeparser", :libRDKitmaeparser),
    # LibraryProduct("libRDKitMolDraw2D", :libRDKitMolDraw2D),
    # LibraryProduct("libRDKitDepictor", :libRDKitDepictor),
    # LibraryProduct("libRDKitRDInchiLib", :libRDKitRDInchiLib),
]

dependencies = [
    Dependency("FreeType2_jll"),
    Dependency("boost_jll"),
    Dependency("Eigen_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version=v"5", julia_compat="^$(julia_version.major).$(julia_version.minor)", experimental=true)
