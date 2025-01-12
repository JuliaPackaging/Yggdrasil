using BinaryBuilder, Pkg

name = "ITK"
version = v"5.4.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/InsightSoftwareConsortium/ITK.git", "311b7060ef39e371f3cd209ec135284ff5fde735")
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
    -DHAVE_CLOCK_GETTIME_RUN:STRING=0 \
    -D_libcxx_run_result:STRING=0 \
    -D_libcxx_run_result__TRYRUN_OUTPUT:STRING=0 \
    -Dhave_sse2_extensions_var_EXITCODE:STRING=0 \
    -Dhave_sse2_extensions_var_EXITCODE__TRYRUN_OUTPUT:STRING=0

cmake --build build --parallel ${nproc}
cmake --install build
install_license ${WORKSPACE}/srcdir/ITK/LICENSE

if [[ "${target}" == *x86_64-w64-mingw32* ]]; then
    cp $prefix/lib/libitkminc2-5.4.dll $prefix/bin
    cp $prefix/lib/libitkminc2-5.4.dll.a $prefix/bin
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable problematic platforms
filter!(p -> !(arch(p) == "i686"), platforms)  # SSE2 issues
filter!(!Sys.isfreebsd, platforms)             # FreeBSD issues
filter!(p -> !(arch(p) == "x86_64" && libc(p) == "musl"), platforms)  # musl issues
filter!(p -> !(arch(p) == "riscv64"), platforms)  # RISC-V not supported
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct(["libITKRegistrationMethodsv4", "libITKRegistrationMethodsv4-5.4", "libITKRegistrationMethodsv4-5"], :libITKRegistrationMethodsv4),
    LibraryProduct(["libITKIOCSV", "libITKIOCSV-5.4", "libITKIOCSV-5"], :libITKIOCSV),
    LibraryProduct(["libITKImageFeature", "libITKImageFeature-5.4", "libITKImageFeature-5"], :libITKImageFeature),
    LibraryProduct(["libITKIOStimulate", "libITKIOStimulate-5.4", "libITKIOStimulate-5"], :libITKIOStimulate),
    LibraryProduct(["libITKIOMeshVTK", "libITKIOMeshVTK-5.4", "libITKIOMeshVTK-5"], :libITKIOMeshVTK),
    LibraryProduct(["libITKLabelMap", "libITKLabelMap-5.4", "libITKLabelMap-5"], :libITKLabelMap),
    LibraryProduct(["libITKIOBruker", "libITKIOBruker-5.4", "libITKIOBruker-5"], :libITKIOBruker),
    LibraryProduct(["libitkgdcmDICT", "libitkgdcmDICT-5.4", "libitkgdcmDICT-5"], :libitkgdcmDICT),
    LibraryProduct(["libITKIOJPEG", "libITKIOJPEG-5.4", "libITKIOJPEG-5"], :libITKIOJPEG),
    LibraryProduct(["libITKIOPNG", "libITKIOPNG-5.4", "libITKIOPNG-5"], :libITKIOPNG),
    LibraryProduct(["libITKIOGE", "libITKIOGE-5.4", "libITKIOGE-5"], :libITKIOGE),
    LibraryProduct(["libITKDenoising", "libITKDenoising-5.4", "libITKDenoising-5"], :libITKDenoising),
    LibraryProduct(["libITKIOLSM", "libITKIOLSM-5.4", "libITKIOLSM-5"], :libITKIOLSM),
    LibraryProduct(["libITKniftiio", "libITKniftiio-5.4", "libITKniftiio-5"], :libITKniftiio),
    LibraryProduct(["libITKIOImageBase", "libITKIOImageBase-5.4", "libITKIOImageBase-5"], :libITKIOImageBase),
    LibraryProduct(["libITKTransform", "libITKTransform-5.4", "libITKTransform-5"], :libITKTransform),
    LibraryProduct(["libITKIOMeshFreeSurfer", "libITKIOMeshFreeSurfer-5.4", "libITKIOMeshFreeSurfer-5"], :libITKIOMeshFreeSurfer),
    LibraryProduct(["libITKIOMeshOBJ", "libITKIOMeshOBJ-5.4", "libITKIOMeshOBJ-5"], :libITKIOMeshOBJ),
    LibraryProduct(["libITKDiffusionTensorImage", "libITKDiffusionTensorImage-5.4", "libITKDiffusionTensorImage-5"], :libITKDiffusionTensorImage),
    LibraryProduct(["libITKImageIntensity", "libITKImageIntensity-5.4", "libITKImageIntensity-5"], :libITKImageIntensity),
    LibraryProduct(["libITKIOHDF5", "libITKIOHDF5-5.4", "libITKIOHDF5-5"], :libITKIOHDF5),
    LibraryProduct(["libITKIOIPL", "libITKIOIPL-5.4", "libITKIOIPL-5"], :libITKIOIPL),
    LibraryProduct(["libITKIOGDCM", "libITKIOGDCM-5.4", "libITKIOGDCM-5"], :libITKIOGDCM),
    LibraryProduct(["libITKIOTransformBase", "libITKIOTransformBase-5.4", "libITKIOTransformBase-5"], :libITKIOTransformBase),
    LibraryProduct(["libITKIOMRC", "libITKIOMRC-5.4", "libITKIOMRC-5"], :libITKIOMRC),
    LibraryProduct(["libITKIOGIPL", "libITKIOGIPL-5.4", "libITKIOGIPL-5"], :libITKIOGIPL),
    LibraryProduct(["libITKIOMeshBYU", "libITKIOMeshBYU-5.4", "libITKIOMeshBYU-5"], :libITKIOMeshBYU),
    LibraryProduct(["libITKIOMeta", "libITKIOMeta-5.4", "libITKIOMeta-5"], :libITKIOMeta),
    LibraryProduct(["libITKIOMINC", "libITKIOMINC-5.4", "libITKIOMINC-5"], :libITKIOMINC),
    LibraryProduct(["libITKDeformableMesh", "libITKDeformableMesh-5.4", "libITKDeformableMesh-5"], :libITKDeformableMesh),
    LibraryProduct(["libitkgdcmDSED", "libitkgdcmDSED-5.4", "libitkgdcmDSED-5"], :libitkgdcmDSED),
    LibraryProduct(["libITKIOSpatialObjects", "libITKIOSpatialObjects-5.4", "libITKIOSpatialObjects-5"], :libITKIOSpatialObjects),
    LibraryProduct(["libitkgdcmIOD", "libitkgdcmIOD-5.4", "libitkgdcmIOD-5"], :libitkgdcmIOD),
    LibraryProduct(["libitkgdcmCommon", "libitkgdcmCommon-5.4", "libitkgdcmCommon-5"], :libitkgdcmCommon),
    LibraryProduct(["libITKIONRRD", "libITKIONRRD-5.4", "libITKIONRRD-5"], :libITKIONRRD),
    LibraryProduct(["libITKIOTransformHDF5", "libITKIOTransformHDF5-5.4", "libITKIOTransformHDF5-5"], :libITKIOTransformHDF5),
    LibraryProduct(["libITKIOJPEG2000", "libITKIOJPEG2000-5.4", "libITKIOJPEG2000-5"], :libITKIOJPEG2000),
    LibraryProduct(["libITKIOMeshBase", "libITKIOMeshBase-5.4", "libITKIOMeshBase-5"], :libITKIOMeshBase),
    LibraryProduct(["libITKIOBMP", "libITKIOBMP-5.4", "libITKIOBMP-5"], :libITKIOBMP),
    LibraryProduct(["libITKIOBioRad", "libITKIOBioRad-5.4", "libITKIOBioRad-5"], :libITKIOBioRad),
    LibraryProduct(["libITKCommon", "libITKCommon-5.4", "libITKCommon-5"], :libITKCommon),
    LibraryProduct(["libITKSpatialObjects", "libITKSpatialObjects-5.4", "libITKSpatialObjects-5"], :libITKSpatialObjects),
    LibraryProduct(["libITKDICOMParser", "libITKDICOMParser-5.4", "libITKDICOMParser-5"], :libITKDICOMParser),
    LibraryProduct(["libITKIOMeshOFF", "libITKIOMeshOFF-5.4", "libITKIOMeshOFF-5"], :libITKIOMeshOFF),
    LibraryProduct(["libITKIOMeshGifti", "libITKIOMeshGifti-5.4", "libITKIOMeshGifti-5"], :libITKIOMeshGifti),
    LibraryProduct(["libITKMetaIO", "libITKMetaIO-5.4", "libITKMetaIO-5"], :libITKMetaIO),
    LibraryProduct(["libITKIONIFTI", "libITKIONIFTI-5.4", "libITKIONIFTI-5"], :libITKIONIFTI),
    LibraryProduct(["libITKNrrdIO", "libITKNrrdIO-5.4", "libITKNrrdIO-5"], :libITKNrrdIO),
    LibraryProduct(["libITKConvolution", "libITKConvolution-5.4", "libITKConvolution-5"], :libITKConvolution),
    LibraryProduct(["libITKTestKernel", "libITKTestKernel-5.4", "libITKTestKernel-5"], :libITKTestKernel),
    LibraryProduct(["libITKBiasCorrection", "libITKBiasCorrection-5.4", "libITKBiasCorrection-5"], :libITKBiasCorrection),
    LibraryProduct(["libITKFastMarching", "libITKFastMarching-5.4", "libITKFastMarching-5"], :libITKFastMarching),
    LibraryProduct(["libITKPolynomials", "libITKPolynomials-5.4", "libITKPolynomials-5"], :libITKPolynomials),
    LibraryProduct(["libITKColormap", "libITKColormap-5.4", "libITKColormap-5"], :libITKColormap),
    LibraryProduct(["libITKPDEDeformableRegistration", "libITKPDEDeformableRegistration-5.4", "libITKPDEDeformableRegistration-5"], :libITKPDEDeformableRegistration),
    LibraryProduct(["libITKIOSiemens", "libITKIOSiemens-5.4", "libITKIOSiemens-5"], :libITKIOSiemens),
    LibraryProduct(["libITKIOTransformInsightLegacy", "libITKIOTransformInsightLegacy-5.4", "libITKIOTransformInsightLegacy-5"], :libITKIOTransformInsightLegacy),
    LibraryProduct(["libITKIOTransformMatlab", "libITKIOTransformMatlab-5.4", "libITKIOTransformMatlab-5"], :libITKIOTransformMatlab),
    LibraryProduct(["libITKKLMRegionGrowing", "libITKKLMRegionGrowing-5.4", "libITKKLMRegionGrowing-5"], :libITKKLMRegionGrowing),
    LibraryProduct(["libITKMarkovRandomFieldsClassifiers", "libITKMarkovRandomFieldsClassifiers-5.4", "libITKMarkovRandomFieldsClassifiers-5"], :libITKMarkovRandomFieldsClassifiers),
    LibraryProduct(["libITKQuadEdgeMeshFiltering", "libITKQuadEdgeMeshFiltering-5.4", "libITKQuadEdgeMeshFiltering-5"], :libITKQuadEdgeMeshFiltering),
    LibraryProduct(["libITKRegionGrowing", "libITKRegionGrowing-5.4", "libITKRegionGrowing-5"], :libITKRegionGrowing),
    LibraryProduct(["libITKVTK", "libITKVTK-5.4", "libITKVTK-5"], :libITKVTK),
    LibraryProduct(["libITKWatersheds", "libITKWatersheds-5.4", "libITKWatersheds-5"], :libITKWatersheds),
    LibraryProduct(["libITKVideoIO", "libITKVideoIO-5.4", "libITKVideoIO-5"], :libITKVideoIO),
    LibraryProduct(["libitkgdcmMSFF", "libitkgdcmMSFF-5.4", "libitkgdcmMSFF-5"], :libitkgdcmMSFF),
    LibraryProduct(["libITKgiftiio", "libITKgiftiio-5.4", "libITKgiftiio-5"], :libITKgiftiio),
    LibraryProduct(["libITKQuadEdgeMesh", "libITKQuadEdgeMesh-5.4", "libITKQuadEdgeMesh-5"], :libITKQuadEdgeMesh),
    LibraryProduct(["libITKznz", "libITKznz-5.4", "libITKznz-5"], :libITKznz),
    LibraryProduct(["libITKIOVTK", "libITKIOVTK-5.4", "libITKIOVTK-5"], :libITKIOVTK),
    LibraryProduct(["libITKFFT", "libITKFFT-5.4", "libITKFFT-5"], :libITKFFT),
    LibraryProduct(["libitkopenjpeg", "libitkopenjpeg-5.4", "libitkopenjpeg-5"], :libitkopenjpeg),
    LibraryProduct(["libITKIOTIFF", "libITKIOTIFF-5.4", "libITKIOTIFF-5"], :libITKIOTIFF),
    LibraryProduct(["libitkminc2", "libitkminc2-5.4", "libitkminc2-5"], :libitkminc2),
    LibraryProduct(["libITKIOXML", "libITKIOXML-5.4", "libITKIOXML-5"], :libITKIOXML),
    LibraryProduct(["libITKTransformFactory", "libITKTransformFactory-5.4", "libITKTransformFactory-5"], :libITKTransformFactory),
    LibraryProduct(["libITKMathematicalMorphology", "libITKMathematicalMorphology-5.4", "libITKMathematicalMorphology-5"], :libITKMathematicalMorphology),
    LibraryProduct(["libITKPath", "libITKPath-5.4", "libITKPath-5"], :libITKPath),
    LibraryProduct(["libITKMesh", "libITKMesh-5.4", "libITKMesh-5"], :libITKMesh),
    LibraryProduct(["libITKSmoothing", "libITKSmoothing-5.4", "libITKSmoothing-5"], :libITKSmoothing),
    LibraryProduct(["libITKOptimizersv4", "libITKOptimizersv4-5.4", "libITKOptimizersv4-5"], :libITKOptimizersv4),
    LibraryProduct(["libITKOptimizers", "libITKOptimizers-5.4", "libITKOptimizers-5"], :libITKOptimizers),
    LibraryProduct(["libITKStatistics", "libITKStatistics-5.4", "libITKStatistics-5"], :libITKStatistics),
    LibraryProduct(["libitkNetlibSlatec", "libitkNetlibSlatec-5.4", "libitkNetlibSlatec-5"], :libitkNetlibSlatec),
    LibraryProduct(["libitklbfgs", "libitklbfgs-5.4", "libitklbfgs-5"], :libitklbfgs),
    LibraryProduct(["libITKVideoCore", "libITKVideoCore-5.4", "libITKVideoCore-5"], :libITKVideoCore),
    LibraryProduct(["libitkdouble-conversion","libitkdouble-conversion-5.4", "libitkdouble-conversion-5"], :libitkdoubleConversion),
    LibraryProduct(["libitksys", "libitksys-5.4", "libitksys-5"], :libitksys),
    LibraryProduct(["libITKVNLInstantiation", "libITKVNLInstantiation-5.4", "libITKVNLInstantiation-5"], :libITKVNLInstantiation),
    LibraryProduct(["libitkvnl_algo", "libitkvnl_algo-5.4", "libitkvnl_algo-5"], :libitkvnl_algo),
    LibraryProduct(["libitkvnl", "libitkvnl-5.4", "libitkvnl-5"], :libitkvnl),
    LibraryProduct(["libitkv3p_netlib", "libitkv3p_netlib-5.4", "libitkv3p_netlib-5"], :libitkv3p_netlib),
    LibraryProduct(["libitkvcl", "libitkvcl-5.4", "libitkvcl-5"], :libitkvcl)
]

dependencies = [
    Dependency(PackageSpec(name="Expat_jll", uuid="2e619515-83b5-522b-bb60-26c02a35a201")),
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a")),
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59")),
    Dependency(PackageSpec(name="JpegTurbo_jll", uuid="aacddb02-875f-59d6-b918-886e6ef4fbf8")),
    Dependency(PackageSpec(name="Libtiff_jll", uuid="89763e89-9b03-5906-acba-b20f662cd828")),
    Dependency(PackageSpec(name="libpng_jll", uuid="b53b4c65-9356-5827-b1ea-8c7a1a84506f")),
    Dependency(PackageSpec(name="Eigen_jll", uuid="bc6bbf8a-a594-5541-9c57-10b0d0312c70")),
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a")),
    Dependency(PackageSpec(name="Libiconv_jll", uuid="94ce4f54-9a6c-5748-9c1c-f9c7231a4531"))  # Add Libiconv_jll for Windows
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8.1.0")
