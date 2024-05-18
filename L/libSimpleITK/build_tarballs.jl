# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libSimpleITK"
version = v"2.2.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/SimpleITK/SimpleITK/releases/download/v$(version)/SimpleITK-$(version).tar.gz", "b07bb98707556ebc2b79aac22dc14950749f509e5b43da8043233275aa55488a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mount -t tmpfs -o size=12G tmpfs /workspace/srcdir
cd ..
cd ..
cd workspace/srcdir
ls
wget https://github.com/SimpleITK/SimpleITK/releases/download/v2.2.0/SimpleITK-2.2.0.tar.gz
ls
tar -xvzf ./SimpleITK-2.2.0.tar.gz 
mkdir SimpleITK-build
cd SimpleITK-build/
cmake -DCMAKE_INSTALL_PREFIX:FILEPATH=/workspace/destdir -DCMAKE_BUILD_TYPE:STRING=RELEASE -DBUILD_SHARED_LIBS:BOOL=ON ../SimpleITK-2.2.0/SuperBuild
make -j10
cd SimpleITK-build/
make install
cd ..
cd ..
ls
cd ..
cd destdir
ls
cd include/
ls
cd SimpleITK-2.2/
l
ls
cd ..
logout
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libSimpleITK_ITKRegistrationCommon", :libSimpleITK_ITKRegistrationCommon),
    LibraryProduct("libSimpleITK_ITKImageFunction", :libSimpleITK_ITKImageFunction),
    LibraryProduct("libSimpleITK_ITKImageFilterBase", :libSimpleITK_ITKImageFilterBase),
    LibraryProduct("libSimpleITK_ITKDenoising", :libSimpleITK_ITKDenoising),
    LibraryProduct("libSimpleITK_ITKBinaryMathematicalMorphology", :libSimpleITK_ITKBinaryMathematicalMorphology),
    LibraryProduct("libSimpleITKBasicFilters0", :libSimpleITKBasicFilters),
    LibraryProduct("libSimpleITK_ITKConvolution", :libSimpleITK_ITKConvolution),
    LibraryProduct("libSimpleITK_ITKImageSources", :libSimpleITK_ITKImageSources),
    LibraryProduct("libSimpleITK_ITKWatersheds", :libSimpleITK_ITKWatersheds),
    LibraryProduct("libSimpleITK_ITKPDEDeformableRegistration", :libSimpleITK_ITKPDEDeformableRegistration),
    LibraryProduct("libSimpleITK_ITKImageNoise", :libSimpleITK_ITKImageNoise),
    LibraryProduct("libSimpleITK_ITKImageFeature", :libSimpleITK_ITKImageFeature),
    LibraryProduct("libSimpleITK_ITKAnisotropicSmoothing", :libSimpleITK_ITKAnisotropicSmoothing),
    LibraryProduct("libSimpleITK_ITKMathematicalMorphology", :libSimpleITK_ITKMathematicalMorphology),
    LibraryProduct("libSimpleITKBasicFilters1", :libSimpleITKBasicFilters),
    LibraryProduct("libSimpleITK_ITKConnectedComponents", :libSimpleITK_ITKConnectedComponents),
    LibraryProduct("libSimpleITK_ITKLabelMap", :libSimpleITK_ITKLabelMap),
    LibraryProduct("libSimpleITK_ITKClassifiers", :libSimpleITK_ITKClassifiers),
    LibraryProduct("libSimpleITK_ITKReview", :libSimpleITK_ITKReview),
    LibraryProduct("libSimpleITK_ITKRegionGrowing", :libSimpleITK_ITKRegionGrowing),
    LibraryProduct("libSimpleITK_ITKTransform", :libSimpleITK_ITKTransform),
    LibraryProduct("libSimpleITK_ITKFastMarching", :libSimpleITK_ITKFastMarching),
    LibraryProduct("libSimpleITK_ITKImageCompare", :libSimpleITK_ITKImageCompare),
    LibraryProduct("libSimpleITK_ITKLabelVoting", :libSimpleITK_ITKLabelVoting),
    LibraryProduct("libSimpleITK_ITKDeconvolution", :libSimpleITK_ITKDeconvolution),
    LibraryProduct("libSimpleITK_ITKAntiAlias", :libSimpleITK_ITKAntiAlias),
    LibraryProduct("libSimpleITK_ITKImageFusion", :libSimpleITK_ITKImageFusion),
    LibraryProduct("libSimpleITK_ITKImageCompose", :libSimpleITK_ITKImageCompose),
    LibraryProduct("libSimpleITK_ITKColormap", :LibSimpleITK_ITKColormap),
    LibraryProduct("libSimpleITK_ITKLevelSets", :libSimpleITK_ITKLevelSets),
    LibraryProduct("libSimpleITK_ITKFFT", :libSimpleITK_ITKFFT),
    LibraryProduct("libSimpleITK_ITKCommon", :libSimpleITK_ITKCommon),
    LibraryProduct("libSimpleITKCommon", :libSimpleITKCommon),
    LibraryProduct("libSimpleITK_ITKThresholding", :libSimpleITK_ITKThresholding),
    LibraryProduct("libSimpleITK_ITKImageGradient", :libSimpleITK_ITKImageGradient),
    LibraryProduct("libSimpleITK_ITKImageIntensity", :libSimpleITK_ITKImageIntensity),
    LibraryProduct("libSimpleITK_ITKBiasCorrection", :libSimpleITK_ITKBiasCorrection),
    LibraryProduct("libSimpleITK_ITKSmoothing", :libSimpleITK_ITKSmoothing),
    LibraryProduct("libSimpleITK_ITKSuperPixel", :libSimpleITK_ITKSuperPixel),
    LibraryProduct("libSimpleITKRegistration", :libSimpleITKRegistration),
    LibraryProduct("libSimpleITK_SimpleITKFilters", :libSimpleITK_SimpleITKFilters),
    LibraryProduct("libSimpleITK_ITKImageLabel", :libSimpleITK_ITKImageLabel),
    LibraryProduct("libSimpleITK_ITKDisplacementField", :libSimpleITK_ITKDisplacementField),
    LibraryProduct("libSimpleITK_ITKImageGrid", :libSimpleITK_ITKImageGrid),
    LibraryProduct("libSimpleITK_ITKImageStatistics", :libSimpleITK_ITKImageStatistics),
    LibraryProduct("libSimpleITK_ITKDistanceMap", :libSimpleITK_ITKDistanceMap),
    LibraryProduct("libSimpleITK_ITKCurvatureFlow", :libSimpleITK_ITKCurvatureFlow),
    LibraryProduct("libSimpleITKIO", :libSimpleITKIO),
    ExecutableProduct("sitkCompareDriver", :sitkCompareDriver)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
