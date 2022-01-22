# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TempestRemap"
version = v"2.1.2"
sources = [
    ArchiveSource("https://github.com/ClimateGlobalChange/tempestremap/archive/refs/tags/v$(version).tar.gz",
                  "18421e1b81ecb5b2aa3bb8f3e9df084586d90c13b27960b78202d264f587934e"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/tempestremap*

export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"
export LDFLAGS_MAKE="${LDFLAGS}"
CONFIGURE_OPTIONS=""

autoreconf -fiv
mkdir -p build && cd build

../configure \
  --prefix=${prefix} \
  --host=${target} \
  --with-blas=blastrampoline \
  --with-lapack=blastrampoline \
  --with-netcdf=${prefix} \
  --with-hdf5=${prefix} \
  --enable-shared \
  --disable-static

make LDFLAGS="${LDFLAGS_MAKE}" -j${nproc} all
make install

install_license ../LICENSE
"""

# Note: We are restricted to the platforms that NetCDF supports, the library is Unix only
platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
] 
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
    Dependency("libblastrampoline_jll"),
    Dependency("NetCDF_jll"),
    Dependency("HDF5_jll"),
    # The following is adapted from NetCDF_jll
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version=v"2.24.0")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat="1.7",
)
