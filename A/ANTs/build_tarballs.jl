# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ANTs"
version = v"2.3.4"

# Collection of sources required to complete build
sources = [
    GitSource("git://github.com/ANTsX/ANTs.git", "857b744cc6eeb72d5cd388933a3492846274cfdf")
]

# Bash recipe for building across all platforms
script = raw"""
cd ANTs
mkdir install
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DRUN_LONG_TESTS=OFF \
    -DRUN_SHORT_TESTS=OFF \
    ..

make -j${nproc}

cd ANTS-build
make install
"""

# script mostly taken from https://github.com/cookpa/antsInstallExample/blob/master/installANTs.sh

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    ExecutableProduct("ANTS", :ANTS),
    ExecutableProduct("ANTSIntegrateVectorField", :ANTSIntegrateVectorField),
    ExecutableProduct("ANTSIntegrateVelocityField", :ANTSIntegrateVelocityField),
    ExecutableProduct("ANTSJacobian", :ANTSJacobian),
    ExecutableProduct("ANTSUseDeformationFieldToGetAffineTransform", :ANTSUseDeformationFieldToGetAffineTransform),
    ExecutableProduct("ANTSUseLandmarkImagesToGetAffineTransform", :ANTSUseLandmarkImagesToGetAffineTransform),
    ExecutableProduct("ANTSUseLandmarkImagesToGetBSplineDisplacementField", :ANTSUseLandmarkImagesToGetBSplineDisplacementField),
    ExecutableProduct("ANTSpexec.sh", :ANTSpexec.sh),
    ExecutableProduct("AddNoiseToImage", :AddNoiseToImage),
    ExecutableProduct("Atropos", :Atropos),
    ExecutableProduct("AverageAffineTransform", :AverageAffineTransform),
    ExecutableProduct("AverageAffineTransformNoRigid", :AverageAffineTransformNoRigid),
    ExecutableProduct("AverageImages", :AverageImages),
    ExecutableProduct("AverageTensorImages", :AverageTensorImages),
    ExecutableProduct("ClusterImageStatistics", :ClusterImageStatistics),
    ExecutableProduct("ComposeMultiTransform", :ComposeMultiTransform),
    ExecutableProduct("CompositeTransformUtil", :CompositeTransformUtil),
    ExecutableProduct("ConvertImage", :ConvertImage),
    ExecutableProduct("ConvertImagePixelType", :ConvertImagePixelType),
    ExecutableProduct("ConvertInputImagePixelTypeToFloat", :ConvertInputImagePixelTypeToFloat),
    ExecutableProduct("ConvertScalarImageToRGB", :ConvertScalarImageToRGB),
    ExecutableProduct("ConvertToJpg", :ConvertToJpg),
    ExecutableProduct("ConvertTransformFile", :ConvertTransformFile),
    ExecutableProduct("CopyImageHeaderInformation", :CopyImageHeaderInformation),
    ExecutableProduct("CreateDTICohort", :CreateDTICohort),
    ExecutableProduct("CreateDisplacementField", :CreateDisplacementField),
    ExecutableProduct("CreateImage", :CreateImage),
    ExecutableProduct("CreateJacobianDeterminantImage", :CreateJacobianDeterminantImage),
    ExecutableProduct("CreateTiledMosaic", :CreateTiledMosaic),
    ExecutableProduct("CreateWarpedGridImage", :CreateWarpedGridImage),
    ExecutableProduct("DeNrrd", :DeNrrd),
    ExecutableProduct("DenoiseImage", :DenoiseImage),
    ExecutableProduct("ExtractRegionFromImage", :ExtractRegionFromImage),
    ExecutableProduct("ExtractRegionFromImageByMask", :ExtractRegionFromImageByMask),
    ExecutableProduct("ExtractSliceFromImage", :ExtractSliceFromImage),
    ExecutableProduct("FitBSplineToPoints", :FitBSplineToPoints),
    ExecutableProduct("GetConnectedComponentsFeatureImages", :GetConnectedComponentsFeatureImages),
    ExecutableProduct("ImageCompare", :ImageCompare),
    ExecutableProduct("ImageIntensityStatistics", :ImageIntensityStatistics),
    ExecutableProduct("ImageMath", :ImageMath),
    ExecutableProduct("ImageSetStatistics", :ImageSetStatistics),
    ExecutableProduct("KellyKapowski", :KellyKapowski),
    ExecutableProduct("KellySlater", :KellySlater),
    ExecutableProduct("LabelClustersUniquely", :LabelClustersUniquely),
    ExecutableProduct("LabelGeometryMeasures", :LabelGeometryMeasures),
    ExecutableProduct("LabelOverlapMeasures", :LabelOverlapMeasures),
    ExecutableProduct("LaplacianThickness", :LaplacianThickness),
    ExecutableProduct("LesionFilling", :LesionFilling),
    ExecutableProduct("MeasureImageSimilarity", :MeasureImageSimilarity),
    ExecutableProduct("MeasureMinMaxMean", :MeasureMinMaxMean),
    ExecutableProduct("MemoryTest", :MemoryTest),
    ExecutableProduct("MultiplyImages", :MultiplyImages),
    ExecutableProduct("N3BiasFieldCorrection", :N3BiasFieldCorrection),
    ExecutableProduct("N4BiasFieldCorrection", :N4BiasFieldCorrection),
    ExecutableProduct("NonLocalSuperResolution", :NonLocalSuperResolution),
    ExecutableProduct("PasteImageIntoImage", :PasteImageIntoImage),
    ExecutableProduct("PermuteFlipImageOrientationAxes", :PermuteFlipImageOrientationAxes),
    ExecutableProduct("PrintHeader", :PrintHeader),
    ExecutableProduct("RebaseTensorImage", :RebaseTensorImage),
    ExecutableProduct("ReorientTensorImage", :ReorientTensorImage),
    ExecutableProduct("ResampleImage", :ResampleImage),
    ExecutableProduct("ResampleImageBySpacing", :ResampleImageBySpacing),
    ExecutableProduct("ResetDirection", :ResetDirection),
    ExecutableProduct("SetDirectionByMatrix", :SetDirectionByMatrix),
    ExecutableProduct("SetOrigin", :SetOrigin),
    ExecutableProduct("SetSpacing", :SetSpacing),
    ExecutableProduct("SimulateDisplacementField", :SimulateDisplacementField),
    ExecutableProduct("SmoothDisplacementField", :SmoothDisplacementField),
    ExecutableProduct("SmoothImage", :SmoothImage),
    ExecutableProduct("StackSlices", :StackSlices),
    ExecutableProduct("SuperResolution", :SuperResolution),
    ExecutableProduct("SurfaceBasedSmoothing", :SurfaceBasedSmoothing),
    ExecutableProduct("SurfaceCurvature", :SurfaceCurvature),
    ExecutableProduct("TextureCooccurrenceFeatures", :TextureCooccurrenceFeatures),
    ExecutableProduct("TextureRunLengthFeatures", :TextureRunLengthFeatures),
    ExecutableProduct("ThresholdImage", :ThresholdImage),
    ExecutableProduct("TileImages", :TileImages),
    ExecutableProduct("TimeSCCAN", :TimeSCCAN),
    ExecutableProduct("WarpImageMultiTransform", :WarpImageMultiTransform),
    ExecutableProduct("WarpTensorImageMultiTransform", :WarpTensorImageMultiTransform),
    ExecutableProduct("WarpTimeSeriesImageMultiTransform", :WarpTimeSeriesImageMultiTransform),
    ExecutableProduct("antsAI", :antsAI),
    ExecutableProduct("antsAffineInitializer", :antsAffineInitializer),
    ExecutableProduct("antsAlignOrigin", :antsAlignOrigin),
    ExecutableProduct("antsApplyTransforms", :antsApplyTransforms),
    ExecutableProduct("antsApplyTransformsToPoints", :antsApplyTransformsToPoints),
    ExecutableProduct("antsJointFusion", :antsJointFusion),
    ExecutableProduct("antsJointTensorFusion", :antsJointTensorFusion),
    ExecutableProduct("antsLandmarkBasedTransformInitializer", :antsLandmarkBasedTransformInitializer),
    ExecutableProduct("antsMotionCorr", :antsMotionCorr),
    ExecutableProduct("antsMotionCorrDiffusionDirection", :antsMotionCorrDiffusionDirection),
    ExecutableProduct("antsMotionCorrStats", :antsMotionCorrStats),
    ExecutableProduct("antsNeuroimagingBattery", :antsNeuroimagingBattery),
    ExecutableProduct("antsRegistration", :antsRegistration),
    ExecutableProduct("antsSliceRegularizedRegistration", :antsSliceRegularizedRegistration),
    ExecutableProduct("antsTransformInfo", :antsTransformInfo),
    ExecutableProduct("antsUtilitiesTesting", :antsUtilitiesTesting),
    ExecutableProduct("compareTwoTransforms", :compareTwoTransforms),
    ExecutableProduct("iMath", :iMath),
    ExecutableProduct("sccan", :sccan),
    ExecutableProduct("simpleSynRegistration", :simpleSynRegistration),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)