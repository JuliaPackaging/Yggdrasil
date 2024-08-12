# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ITK"
version = v"5.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/InsightSoftwareConsortium/ITK.git", "1fc47c7bec4ee133318c1892b7b745763a17d411")
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "${target}" == *x86_64-w64-mingw32* ]]; then
    CONFIG=msys2-64
    OS=Windows

fi
export LDFLAGS="-L${libdir}"
cd $WORKSPACE/srcdir/ITK*
mkdir build/
cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DITK_USE_SYSTEM_EXPAT:BOOL=ON \
    -DITK_USE_SYSTEM_FFTW:BOOL=ON \
    -DITK_USE_SYSTEM_HDF5:BOOL=ON \
    -DITK_USE_SYSTEM_JPEG:BOOL=ON \
    -DITK_USE_SYSTEM_TIFF:BOOL=ON \
    -DITK_USE_SYSTEM_PNG:BOOL=ON \
    -DITK_USE_SYSTEM_EIGEN:BOOL=ON \
    -DITK_USE_SYSTEM_ZLIB:BOOL=ON \
    -DQNANHIBIT_VALUE:BOOL=0 \
    -DQNANHIBIT_VALUE__TRYRUN_OUTPUT:STRING=0 \
    -DVXL_HAS_SSE2_HARDWARE_SUPPORT:STRING=1 \
    -DVCL_HAS_LFS:STRING=1 \
    -DDOUBLE_CONVERSION_CORRECT_DOUBLE_OPERATIONS:STRING=1 \
    -DHAVE_CLOCK_GETTIME_RUN:STRING=0
cmake --build build --parallel ${nproc}
cmake --install build
install_license ${WORKSPACE}/srcdir/ITK/LICENSE
if [[ "${target}" == *x86_64-w64-mingw32* ]]; then
    cp $prefix/lib/libitkminc2-5.3.dll $prefix/bin
    cp $prefix/lib/libitkminc2-5.3.dll.a $prefix/bin
fi
"""



# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

#sse2 disabled errors in ITK with open issues on github for i686 platforms [https://github.com/InsightSoftwareConsortium/ITK/issues/2529] [https://github.com/microsoft/vcpkg/issues/37574]
filter!(p -> !(arch(p) == "i686"), platforms)

#CMAKE errors for _libcxx_run_result in cross compilation for macOS, freebsd and x86_64 linux musl
filter!(!Sys.isapple, platforms)
filter!(!Sys.isfreebsd, platforms)
filter!(p -> !(arch(p) == "x86_64" && libc(p) == "musl"), platforms)

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libITKRegistrationMethodsv4", "libITKRegistrationMethodsv4-5.3"], :libITKRegistrationMethodsv4),
    LibraryProduct(["libITKIOCSV", "libITKIOCSV-5.3"], :libITKIOCSV),
    LibraryProduct(["libITKImageFeature", "libITKImageFeature-5.3"], :libITKImageFeature),
    LibraryProduct(["libITKIOStimulate", "libITKIOStimulate-5.3"], :libITKIOStimulate),
    LibraryProduct(["libITKIOMeshVTK", "libITKIOMeshVTK-5.3"], :libITKIOMeshVTK),
    LibraryProduct(["libITKLabelMap", "libITKLabelMap-5.3"], :libITKLabelMap),
    LibraryProduct(["libITKIOBruker", "libITKIOBruker-5.3"], :libITKIOBruker),
    LibraryProduct(["libitkgdcmDICT", "libitkgdcmDICT-5.3"], :libitkgdcmDICT),
    LibraryProduct(["libITKIOJPEG", "libITKIOJPEG-5.3"], :libITKIOJPEG),
    LibraryProduct(["libITKIOPNG", "libITKIOPNG-5.3"], :libITKIOPNG),
    LibraryProduct(["libITKIOGE", "libITKIOGE-5.3"], :libITKIOGE),
    LibraryProduct(["libITKDenoising", "libITKDenoising-5.3"], :libITKDenoising),
    LibraryProduct(["libITKIOLSM", "libITKIOLSM-5.3"], :libITKIOLSM),
    LibraryProduct(["libITKniftiio", "libITKniftiio-5.3"], :libITKniftiio),
    LibraryProduct(["libITKIOImageBase", "libITKIOImageBase-5.3"], :libITKIOImageBase),
    LibraryProduct(["libITKTransform", "libITKTransform-5.3"], :libITKTransform),
    LibraryProduct(["libITKIOMeshFreeSurfer", "libITKIOMeshFreeSurfer-5.3"], :libITKIOMeshFreeSurfer),
    LibraryProduct(["libITKIOMeshOBJ", "libITKIOMeshOBJ-5.3"], :libITKIOMeshOBJ),
    LibraryProduct(["libITKDiffusionTensorImage", "libITKDiffusionTensorImage-5.3"], :libITKDiffusionTensorImage),
    LibraryProduct(["libITKImageIntensity", "libITKImageIntensity-5.3"], :libITKImageIntensity),
    LibraryProduct(["libITKIOHDF5", "libITKIOHDF5-5.3"], :libITKIOHDF5),
    LibraryProduct(["libITKIOIPL", "libITKIOIPL-5.3"], :libITKIOIPL),
    LibraryProduct(["libITKIOGDCM", "libITKIOGDCM-5.3"], :libITKIOGDCM),
    LibraryProduct(["libITKIOTransformBase", "libITKIOTransformBase-5.3"], :libITKIOTransformBase),
    LibraryProduct(["libITKIOMRC", "libITKIOMRC-5.3"], :libITKIOMRC),
    LibraryProduct(["libITKIOGIPL", "libITKIOGIPL-5.3"], :libITKIOGIPL),
    LibraryProduct(["libITKIOMeshBYU", "libITKIOMeshBYU-5.3"], :libITKIOMeshBYU),
    LibraryProduct(["libITKIOMeta", "libITKIOMeta-5.3"], :libITKIOMeta),
    LibraryProduct(["libITKIOMINC", "libITKIOMINC-5.3"], :libITKIOMINC),
    LibraryProduct(["libITKDeformableMesh", "libITKDeformableMesh-5.3"], :libITKDeformableMesh),
    LibraryProduct(["libitkgdcmDSED", "libitkgdcmDSED-5.3"], :libitkgdcmDSED),
    LibraryProduct(["libITKIOSpatialObjects", "libITKIOSpatialObjects-5.3"], :libITKIOSpatialObjects),
    LibraryProduct(["libitkgdcmIOD", "libitkgdcmIOD-5.3"], :libitkgdcmIOD),
    LibraryProduct(["libitkgdcmCommon", "libitkgdcmCommon-5.3"], :libitkgdcmCommon),
    LibraryProduct(["libITKIONRRD", "libITKIONRRD-5.3"], :libITKIONRRD),
    LibraryProduct(["libITKIOTransformHDF5", "libITKIOTransformHDF5-5.3"], :libITKIOTransformHDF5),
    LibraryProduct(["libITKIOJPEG2000", "libITKIOJPEG2000-5.3"], :libITKIOJPEG2000),
    LibraryProduct(["libITKIOMeshBase", "libITKIOMeshBase-5.3"], :libITKIOMeshBase),
    LibraryProduct(["libITKIOBMP", "libITKIOBMP-5.3"], :libITKIOBMP),
    LibraryProduct(["libITKIOBioRad", "libITKIOBioRad-5.3"], :libITKIOBioRad),
    LibraryProduct(["libITKCommon", "libITKCommon-5.3"], :libITKCommon),
    LibraryProduct(["libITKSpatialObjects", "libITKSpatialObjects-5.3"], :libITKSpatialObjects),
    LibraryProduct(["libITKDICOMParser", "libITKDICOMParser-5.3"], :libITKDICOMParser),
    LibraryProduct(["libITKIOMeshOFF", "libITKIOMeshOFF-5.3"], :libITKIOMeshOFF),
    LibraryProduct(["libITKIOMeshGifti", "libITKIOMeshGifti-5.3"], :libITKIOMeshGifti),
    LibraryProduct(["libITKMetaIO", "libITKMetaIO-5.3"], :libITKMetaIO),
    LibraryProduct(["libITKIONIFTI", "libITKIONIFTI-5.3"], :libITKIONIFTI),
    LibraryProduct(["libITKNrrdIO", "libITKNrrdIO-5.3"], :libITKNrrdIO),
    LibraryProduct(["libITKConvolution", "libITKConvolution-5.3"], :libITKConvolution),
    LibraryProduct(["libITKTestKernel", "libITKTestKernel-5.3"], :libITKTestKernel),
    LibraryProduct(["libITKBiasCorrection", "libITKBiasCorrection-5.3"], :libITKBiasCorrection),
    LibraryProduct(["libITKFastMarching", "libITKFastMarching-5.3"], :libITKFastMarching),
    LibraryProduct(["libITKPolynomials", "libITKPolynomials-5.3"], :libITKPolynomials),
    LibraryProduct(["libITKColormap", "libITKColormap-5.3"], :libITKColormap),
    LibraryProduct(["libITKPDEDeformableRegistration", "libITKPDEDeformableRegistration-5.3"], :libITKPDEDeformableRegistration),
    LibraryProduct(["libITKIOSiemens", "libITKIOSiemens-5.3"], :libITKIOSiemens),
    LibraryProduct(["libITKIOTransformInsightLegacy", "libITKIOTransformInsightLegacy-5.3"], :libITKIOTransformInsightLegacy),
    LibraryProduct(["libITKIOTransformMatlab", "libITKIOTransformMatlab-5.3"], :libITKIOTransformMatlab),
    LibraryProduct(["libITKKLMRegionGrowing", "libITKKLMRegionGrowing-5.3"], :libITKKLMRegionGrowing),
    LibraryProduct(["libITKMarkovRandomFieldsClassifiers", "libITKMarkovRandomFieldsClassifiers-5.3"], :libITKMarkovRandomFieldsClassifiers),
    LibraryProduct(["libITKQuadEdgeMeshFiltering", "libITKQuadEdgeMeshFiltering-5.3"], :libITKQuadEdgeMeshFiltering),
    LibraryProduct(["libITKRegionGrowing", "libITKRegionGrowing-5.3"], :libITKRegionGrowing),
    LibraryProduct(["libITKVTK", "libITKVTK-5.3"], :libITKVTK),
    LibraryProduct(["libITKWatersheds", "libITKWatersheds-5.3"], :libITKWatersheds),
    LibraryProduct(["libITKVideoIO", "libITKVideoIO-5.3"], :libITKVideoIO),
    LibraryProduct(["libitkgdcmMSFF", "libitkgdcmMSFF-5.3"], :libitkgdcmMSFF),
    LibraryProduct(["libITKgiftiio", "libITKgiftiio-5.3"], :libITKgiftiio),
    LibraryProduct(["libITKQuadEdgeMesh", "libITKQuadEdgeMesh-5.3"], :libITKQuadEdgeMesh),
    LibraryProduct(["libITKznz", "libITKznz-5.3"], :libITKznz),
    LibraryProduct(["libITKIOVTK", "libITKIOVTK-5.3"], :libITKIOVTK),
    LibraryProduct(["libITKFFT", "libITKFFT-5.3"], :libITKFFT),
    LibraryProduct(["libitkopenjpeg", "libitkopenjpeg-5.3"], :libitkopenjpeg),
    LibraryProduct(["libITKIOTIFF", "libITKIOTIFF-5.3"], :libITKIOTIFF),
    LibraryProduct(["libitkminc2", "libitkminc2-5.3"], :libitkminc2),
    LibraryProduct(["libITKIOXML", "libITKIOXML-5.3"], :libITKIOXML),
    LibraryProduct(["libITKTransformFactory", "libITKTransformFactory-5.3"], :libITKTransformFactory),
    LibraryProduct(["libITKMathematicalMorphology", "libITKMathematicalMorphology-5.3"], :libITKMathematicalMorphology),
    LibraryProduct(["libITKPath", "libITKPath-5.3"], :libITKPath),
    LibraryProduct(["libITKMesh", "libITKMesh-5.3"], :libITKMesh),
    LibraryProduct(["libITKSmoothing", "libITKSmoothing-5.3"], :libITKSmoothing),
    LibraryProduct(["libITKOptimizersv4", "libITKOptimizersv4-5.3"], :libITKOptimizersv4),
    LibraryProduct(["libITKOptimizers", "libITKOptimizers-5.3"], :libITKOptimizers),
    LibraryProduct(["libITKStatistics", "libITKStatistics-5.3"], :libITKStatistics),
    LibraryProduct(["libitkNetlibSlatec", "libitkNetlibSlatec-5.3"], :libitkNetlibSlatec),
    LibraryProduct(["libitklbfgs", "libitklbfgs-5.3"], :libitklbfgs),
    LibraryProduct(["libITKVideoCore", "libITKVideoCore-5.3"], :libITKVideoCore),
    LibraryProduct(["libitkdouble-conversion", "libitkdouble-conversion-5.3"], :libitkdoubleConversion),
    LibraryProduct(["libitksys", "libitksys-5.3"], :libitksys),
    LibraryProduct(["libITKVNLInstantiation", "libITKVNLInstantiation-5.3"], :libITKVNLInstantiation),
    LibraryProduct(["libitkvnl_algo", "libitkvnl_algo-5.3"], :libitkvnl_algo),
    LibraryProduct(["libitkvnl", "libitkvnl-5.3"], :libitkvnl),
    LibraryProduct(["libitkv3p_netlib", "libitkv3p_netlib-5.3"], :libitkv3p_netlib),
    LibraryProduct(["libitkvcl", "libitkvcl-5.3"], :libitkvcl)
]


# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201"))
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"))
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"))
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8"))
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828"))
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f"))
    Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8.1.0")
