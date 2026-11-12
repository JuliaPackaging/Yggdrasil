# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TempestRemap"
version = v"2.2.0"
sources = [
    GitSource("https://github.com/ClimateGlobalChange/tempestremap.git",
        "23968403baf1ff978341bf583ea70940bf7c2102"), # v2.2.0
]

script = raw"""
cd ${WORKSPACE}/srcdir/tempestremap*

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"
if [[ "${target}" == *-mingw* ]]; then
    LDFLAGS_MAKE+=" -no-undefined"
fi

if [[ "${target}" == aarch64-apple-darwin* ]]; then
    # aclocal.m4 has some lines where it expects `MACOSX_DEPLOYMENT_TARGET` to be up to
    # version 10.  Let's pretend to be 10.16, as many tools do to make old build systems
    # happy.
    export MACOSX_DEPLOYMENT_TARGET="10.16"
fi
CONFIGURE_OPTIONS=""

autoreconf -fiv
mkdir -p build && cd build

../configure \
  --prefix=${prefix} \
  --host=${target} \
  --with-blas=openblas \
  --with-lapack=openblas \
  --with-netcdf=${prefix} \
  --enable-shared \
  --disable-static

make LDFLAGS="${LDFLAGS_MAKE}" -j${nproc} all
make install

install_license ../LICENSE
"""

# Note: We are restricted to the platforms that NetCDF supports
platforms = supported_platforms(exclude = p -> arch(p) == "powerpc64le" || libc(p) == "musl")
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libTempestRemap", :libTempestRemap),
    ExecutableProduct("AnalyzeMap", :AnalyzeMap_exe),
    ExecutableProduct("ApplyOfflineMap", :ApplyOfflineMap_exe),
    ExecutableProduct("CalculateDiffNorms",  :CalculateDiffNorms_exe),
    ExecutableProduct("CoarsenRectilinearData", :CoarsenRectilinearData_exe),
    ExecutableProduct("GenerateCSMesh", :GenerateCSMesh_exe),
    ExecutableProduct("GenerateGLLMetaData", :GenerateGLLMetaData_exe),
    ExecutableProduct("GenerateICOMesh", :GenerateICOMesh_exe),
    ExecutableProduct("GenerateLambertConfConicMesh", :GenerateLambertConfConicMesh_exe),
    ExecutableProduct("GenerateOfflineMap", :GenerateOfflineMap_exe),
    ExecutableProduct("GenerateOverlapMesh", :GenerateOverlapMesh_exe),
    ExecutableProduct("GenerateOverlapMesh_v1", :GenerateOverlapMesh_v1_exe),
    ExecutableProduct("GenerateRLLMesh", :GenerateRLLMesh_exe),
    ExecutableProduct("GenerateRectilinearMeshFromFile", :GenerateRectilinearMeshFromFile_exe),
    ExecutableProduct("GenerateStereographicMesh", :GenerateStereographicMesh_exe),
    ExecutableProduct("GenerateTestData",  :GenerateTestData_exe),
    ExecutableProduct("GenerateTransectMesh",  :GenerateTransectMesh_exe),
    ExecutableProduct("GenerateTransposeMap", :GenerateTransposeMap_exe),
    ExecutableProduct("GenerateUTMMesh", :GenerateUTMMesh_exe),
    ExecutableProduct("GenerateVolumetricMesh", :GenerateVolumetricMesh_exe),
    ExecutableProduct("MeshToTxt", :MeshToTxt_exe),
    ExecutableProduct("RestructureData", :RestructureData_exe),
    ExecutableProduct("ShpToMesh", :ShpToMesh_exe),
    ExecutableProduct("VerticalInterpolate", :VerticalInterpolate_exe),
]

dependencies = [
    Dependency("OpenBLAS32_jll"),
    # We had to restrict compat with HDF5 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10347#issuecomment-2662923973
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency("HDF5_jll"; compat="1.14.2 - 1.14.3"),
    Dependency("NetCDF_jll", v"400.902.208", compat="~400.902.207"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.7",
)
