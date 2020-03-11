# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "VTKMinimal"
version = v"8.2.0"

# Build a minimal subset of VTK sufficient for rendering purposes. Notably, this leaves
# out HDF5 and MPI, thus creating fewer clash points for transient linking problems.
# Building the full version on BinaryBuilder seems to be feasible, though.      
#
# The platform constraint to linux + FreeBSD comes from the constraints on libXt etc.
# Currently, this depends on the Xorg libraries, therefore it is not available for Mac+Win,
# this situation may change though with Qt.
#
# A couple of libraries (eigen, doubleconversion, ogg, theora) is used in the
# vtk built-in version. It appears to be possible to replace them by jlls upon availability of those.
# Though there is Ogg_jll, the vtktheora does not go well with it.
#
#

# Grab the source directly from the vtk website
sources = [
    "https://www.vtk.org/files/release/8.2/VTK-8.2.0.tar.gz" => "34c3dc775261be5e45a8049155f7228b6bd668106c72a3c435d95730d17d57bb"
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
EXTRA_VARS=()
if [[ "${target}" == *-linux-* ]] || [[ "${target}" == *-freebsd* ]]; then
    # On Linux and FreeBSD this variable by default does `-L/usr/lib`
    EXTRA_VARS+=(LDFLAGS.EXTRA="")
fi


mkdir build
cd build
cmake -DVTK_CUSTOM_LIBRARY_SUFFIX="" -DVTK_USE_SYSTEM_LIBRARIES:BOOL=ON -DVTK_USE_SYSTEM_EIGEN3:BOOL=OFF  -DVTK_USE_SYSTEM_THEORA:BOOL=OFF   -DVTK_USE_SYSTEM_EIGEN=OFF -DVTK_USE_SYSTEM_DOUBLECONVERSION=OFF  -DVTK_USE_SYSTEM_LZMA:BOOL=ON -DVTK_USE_SYSTEM_OGG:BOOL=OFF   -DVTK_USE_SYSTEM_PNG:BOOL=ON  -DVTK_USE_SYSTEM_LZ4=ON -DVTK_USE_SYSTEM_JPEG:BOOL=ON -DVTK_USE_SYSTEM_TIFF:BOOL=ON -DVTK_USE_SYSTEM_ZLIB:BOOL=ON -DVTK_Group_Rendering:BOOL=OFF -DVTK_Group_StandAlone:BOOL=OFF -DModule_vtkCommonCore:BOOL=ON -DModule_vtkCommonDataModel:BOOL=ON -DModule_vtkCommonExecutionModel:BOOL=ON -DModule_vtkCommonMisc:BOOL=ON -DModule_vtkCommonSystem:BOOL=ON -DModule_vtkCommonMath:BOOL=ON -DModule_vtkCommonTransforms:BOOL=ON -DModule_vtkRenderingCore:BOOL=ON -DModule_vtkRenderingContext2D:BOOL=ON -DModule_vtkFiltersCore:BOOL=ON -DModule_vtkFiltersGeneral:BOOL=ON -DModule_vtkFiltersGeometry:BOOL=ON -DModule_vtkFiltersExtraction:BOOL=ON -DModule_vtkFiltersFlowPaths:BOOL=ON -DModule_vtkInteractionWidgets:BOOL=ON -DModule_vtkIOMovie:BOOL=ON -DModule_vtkParallelCore:BOOL=ON -DModule_vtkInteractionStyle:BOOL=ON -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release  ../VTK-8.2.0/
make -j${nproc}
make install

"""
#

#
# for testing during development
# platforms=[Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(;cxxstring_abi=:cxx11))]

platforms = [p for p in supported_platforms() if p isa Union{Linux,FreeBSD}]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libvtkCommonColor",:libvtkCommonColor),
    LibraryProduct("libvtkCommonComputationalGeometry",:libvtkCommonComputationalGeometry),
    LibraryProduct("libvtkCommonCore",:libvtkCommonCore),
    LibraryProduct("libvtkCommonDataModel",:libvtkCommonDataModel),         
    LibraryProduct("libvtkCommonExecutionModel",:libvtkCommonExecutionModel),
    LibraryProduct("libvtkCommonMath",:libvtkCommonMath),
    LibraryProduct("libvtkCommonMisc",:libvtkCommonMisc),
    LibraryProduct("libvtkCommonSystem",:libvtkCommonSystem),
    LibraryProduct("libvtkCommonTransforms",:libvtkCommonTransforms),
    LibraryProduct("libvtkDICOMParser",:libvtkDICOMParser),
    LibraryProduct("libvtkdoubleconversion",:libvtkdoubleconversion),
    LibraryProduct("libvtkFiltersCore",:libvtkFiltersCore),
    LibraryProduct("libvtkFiltersExtraction",:libvtkFiltersExtraction),
    LibraryProduct("libvtkFiltersFlowPaths",:libvtkFiltersFlowPaths),
    LibraryProduct("libvtkFiltersGeneral",:libvtkFiltersGeneral),
    LibraryProduct("libvtkFiltersGeometry",:libvtkFiltersGeometry),
    LibraryProduct("libvtkFiltersHybrid",:libvtkFiltersHybrid),
    LibraryProduct("libvtkFiltersModeling",:libvtkFiltersModeling),
    LibraryProduct("libvtkFiltersSources",:libvtkFiltersSources),
    LibraryProduct("libvtkFiltersStatistics",:libvtkFiltersStatistics),
    LibraryProduct("libvtkImagingColor",:libvtkImagingColor),
    LibraryProduct("libvtkImagingCore",:libvtkImagingCore),
    LibraryProduct("libvtkImagingFourier",:libvtkImagingFourier),
    LibraryProduct("libvtkImagingGeneral",:libvtkImagingGeneral),
    LibraryProduct("libvtkImagingHybrid",:libvtkImagingHybrid),
    LibraryProduct("libvtkImagingMath",:libvtkImagingMath),
    LibraryProduct("libvtkImagingSources",:libvtkImagingSources),
    LibraryProduct("libvtkInteractionStyle",:libvtkInteractionStyle),
    LibraryProduct("libvtkInteractionWidgets",:libvtkInteractionWidgets),
    LibraryProduct("libvtkIOCore",:libvtkIOCore),
    LibraryProduct("libvtkIOImage",:libvtkIOImage),
    LibraryProduct("libvtkIOLegacy",:libvtkIOLegacy),
    LibraryProduct("libvtkIOMovie",:libvtkIOMovie),
    LibraryProduct("libvtkIOXML",:libvtkIOXML),
    LibraryProduct("libvtkIOXMLParser",:libvtkIOXMLParser),
    LibraryProduct("libvtkmetaio",:libvtkmetaio),
    LibraryProduct("libvtkParallelCore",:libvtkParallelCore),
    LibraryProduct("libvtkRenderingAnnotation",:libvtkRenderingAnnotation),
    LibraryProduct("libvtkRenderingContext2D",:libvtkRenderingContext2D),
    LibraryProduct("libvtkRenderingContextOpenGL2",:libvtkRenderingContextOpenGL2),
    LibraryProduct("libvtkRenderingCore",:libvtkRenderingCore),
    LibraryProduct("libvtkRenderingFreeType",:libvtkRenderingFreeType),
    LibraryProduct("libvtkRenderingOpenGL2",:libvtkRenderingOpenGL2),
    LibraryProduct("libvtkRenderingVolume",:libvtkRenderingVolume),
    LibraryProduct("libvtkRenderingVolumeOpenGL2",:libvtkRenderingVolumeOpenGL2),
    LibraryProduct("libvtksys",:libvtksys),
    LibraryProduct("libvtkogg",:libvtkogg),
    LibraryProduct("libvtktheora",:libvtktheora),
#    LibraryProduct("libvtkjpeg",:libvtkjpeg),
#    LibraryProduct("libvtklzma",:libvtklzma),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "GLEW_jll",
    "Xorg_libXi_jll",
    "Xorg_libXtst_jll",
    "Xorg_libXt_jll",
    "Xorg_libICE_jll",
    "Xorg_libSM_jll",
    "Libtiff_jll",
    "JpegTurbo_jll",
    "libpng_jll",
    "Zlib_jll",
    "FreeType2_jll",
    "Expat_jll",
    "Lz4_jll",
    "XZ_jll",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

