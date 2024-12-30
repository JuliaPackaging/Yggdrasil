# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenFOAM_com"
version = v"2312.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://develop.openfoam.com/Development/openfoam.git", "1d8f0d55f79e6488dae75e4b839e358a88af77b5")
]

# In order to set up OpenFOAM, we need to know the version of some of the
# dependencies.
const SCOTCH_VERSION = "6.1.3"
const FFTW_VERSION = "3.3.10"

# Bash recipe for building across all platforms
script = raw"""

cd ${WORKSPACE}/srcdir/openfoam
git submodule update --init modules/cfmesh modules/avalanche

# Adding -rpath-links #TODO need to automate for other platforms
## For linux64
LDFLAGS=""
for dir in "" "/dummy" "/mpi-system"; do
    LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"
done
LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${libdir}"

# Set rpath-link in all C/C++ compilers
sed -i "s|cc         := gcc\$(COMPILER_VERSION)|cc         := cc\$(COMPILER_VERSION) ${LDFLAGS}|" wmake/rules/General/Gcc/c
sed -i "s|CC         := g++\$(COMPILER_VERSION) -std=c++14|CC         := c++\$(COMPILER_VERSION) -std=c++14 ${LDFLAGS}|" wmake/rules/General/Gcc/c++

cat wmake/rules/General/Gcc/c
cat wmake/rules/General/Gcc/c++

# Setup Scotch
sed -i "s|SCOTCH_VERSION=scotch_6.1.0|SCOTCH_VERSION=scotch-system|" etc/config.sh/scotch
sed -i "s|export SCOTCH_ARCH_PATH=\$WM_THIRD_PARTY_DIR/platforms/\$WM_ARCH\$WM_COMPILER\$WM_PRECISION_OPTION\$WM_LABEL_OPTION/\$SCOTCH_VERSION|export SCOTCH_ARCH_PATH=${prefix}|" etc/config.sh/scotch
cat etc/config.sh/scotch

# Setup METIS
sed -i "s|METIS_VERSION=metis-5.1.0|METIS_VERSION=metis-system|" etc/config.sh/metis
sed -i "s|export METIS_ARCH_PATH=\$WM_THIRD_PARTY_DIR/platforms/\$WM_ARCH\$WM_COMPILER\$WM_PRECISION_OPTION\$WM_LABEL_OPTION/\$METIS_VERSION|export METIS_ARCH_PATH=${prefix}|" etc/config.sh/metis
cat etc/config.sh/metis

# Setup FFTW
sed -i "s|fftw_version=fftw-3.3.10|fftw_version=fftw-system|" etc/config.sh/FFTW
sed -i "s|export FFTW_ARCH_PATH=\$WM_THIRD_PARTY_DIR/platforms/\$WM_ARCH\$WM_COMPILER/\$fftw_version|export FFTW_ARCH_PATH=${prefix}|" etc/config.sh/FFTW
cat etc/config.sh/FFTW

# Setup CGAL, BOOST
sed -i "s|boost_version=boost_1_74_0|boost_version=boost-system|" etc/config.sh/CGAL
sed -i "s|cgal_version=CGAL-4.14.3|cgal_version=cgal-system|" etc/config.sh/CGAL
sed -i "s|export BOOST_ARCH_PATH=|export BOOST_ARCH_PATH=${prefix} #|" etc/config.sh/CGAL
sed -i "s|export CGAL_ARCH_PATH=|export CGAL_ARCH_PATH=${prefix} #|" etc/config.sh/CGAL
sed -i "s|# export GMP_ARCH_PATH=...|export GMP_ARCH_PATH=${prefix}|" etc/config.sh/CGAL
sed -i "s|# export MPFR_ARCH_PATH=...|export MPFR_ARCH_PATH=${prefix}|" etc/config.sh/CGAL
cat etc/config.sh/CGAL


# Setup to use our MPI
sed -i "s|WM_MPLIB=SYSTEMOPENMPI|WM_MPLIB=SYSTEMMPI|" etc/bashrc
cat etc/bashrc

export MPI_ROOT="${prefix}"
export MPI_ARCH_FLAGS=""
export MPI_ARCH_INC="-I${includedir}"

if grep -q MPICH_NAME $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi";  
elif grep -q MPItrampoline $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpitrampoline";  
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi";  
fi

# Setup the environment. Failures allowed
source etc/bashrc || true

# Build!
./Allwmake -j${nproc} -q -s

# Copying the binaries and etc to the correct directories
mkdir -p "${libdir}" "${bindir}"
cp platforms/linux64GccDPInt32Opt/lib/{,dummy/,sys-mpi/}*.${dlext}* "${libdir}/."
cp platforms/linux64GccDPInt32Opt/bin/* "${bindir}/."
cp -r etc/ "${prefix}/."
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]
platforms = expand_cxxstring_abis(platforms)

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libadjointOptimisation", :libadjointOptimisation; dont_dlopen=true),
    LibraryProduct("libalphaFieldFunctions", :libalphaFieldFunctions; dont_dlopen=true),
    LibraryProduct("libatmosphericModels", :libatmosphericModels; dont_dlopen=true),
    LibraryProduct("libbarotropicCompressibilityModel", :libbarotropicCompressibilityModel; dont_dlopen=true),
    LibraryProduct("libblockMesh", :libblockMesh; dont_dlopen=true),
    LibraryProduct("libchemistryModel", :libchemistryModel; dont_dlopen=true),
    LibraryProduct("libcoalCombustion", :libcoalCombustion; dont_dlopen=true),
    LibraryProduct("libcombustionModels", :libcombustionModels; dont_dlopen=true),
    LibraryProduct("libcompressibleMultiPhaseTurbulenceModels", :libcompressibleMultiPhaseTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libcompressibleTransportModels", :libcompressibleTransportModels; dont_dlopen=true),
    LibraryProduct("libcompressibleTurbulenceModels", :libcompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libcompressibleTwoPhaseMixtureTurbulenceModels", :libcompressibleTwoPhaseMixtureTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libcompressibleTwoPhaseSystem", :libcompressibleTwoPhaseSystem; dont_dlopen=true),
    LibraryProduct("libconformalVoronoiMesh", :libconformalVoronoiMesh; dont_dlopen=true),
    LibraryProduct("libconversion", :libconversion; dont_dlopen=true),
    LibraryProduct("libcv2DMesh", :libcv2DMesh; dont_dlopen=true),
    LibraryProduct("libdecompose", :libdecompose; dont_dlopen=true),
    LibraryProduct("libdecompositionMethods", :libdecompositionMethods; dont_dlopen=true),
    LibraryProduct("libdistributed", :libdistributed; dont_dlopen=true),
    LibraryProduct("libdistributionModels", :libdistributionModels; dont_dlopen=true),
    LibraryProduct("libDPMTurbulenceModels", :libDPMTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libdriftFluxRelativeVelocityModels", :libdriftFluxRelativeVelocityModels; dont_dlopen=true),
    LibraryProduct("libdriftFluxTransportModels", :libdriftFluxTransportModels; dont_dlopen=true),
    LibraryProduct("libDSMC", :libDSMC; dont_dlopen=true),
    LibraryProduct("libdynamicFvMesh", :libdynamicFvMesh; dont_dlopen=true),
    LibraryProduct("libdynamicMesh", :libdynamicMesh; dont_dlopen=true),
    LibraryProduct("libengine", :libengine; dont_dlopen=true),
    LibraryProduct("libextrude2DMesh", :libextrude2DMesh; dont_dlopen=true),
    LibraryProduct("libextrudeModel", :libextrudeModel; dont_dlopen=true),
    LibraryProduct("libfaAvalanche", :libfaAvalanche; dont_dlopen=true),
    LibraryProduct("libfaDecompose", :libfaDecompose; dont_dlopen=true),
    LibraryProduct("libfaOptions", :libfaOptions; dont_dlopen=true),
    LibraryProduct("libfaReconstruct", :libfaReconstruct; dont_dlopen=true),
    LibraryProduct("libfieldFunctionObjects", :libfieldFunctionObjects; dont_dlopen=true),
    LibraryProduct("libfileFormats", :libfileFormats; dont_dlopen=true),
    LibraryProduct("libfiniteArea", :libfiniteArea; dont_dlopen=true),
    LibraryProduct("libfiniteVolume", :libfiniteVolume; dont_dlopen=true),
    LibraryProduct("libfluidThermophysicalModels", :libfluidThermophysicalModels; dont_dlopen=true),
    LibraryProduct("libforces", :libforces; dont_dlopen=true),
    LibraryProduct("libfvMotionSolvers", :libfvMotionSolvers; dont_dlopen=true),
    LibraryProduct("libfvOptions", :libfvOptions; dont_dlopen=true),
    LibraryProduct("libgenericPatchFields", :libgenericPatchFields; dont_dlopen=true),
    LibraryProduct("libgeometricVoF", :libgeometricVoF; dont_dlopen=true),
    LibraryProduct("libhelpTypes", :libhelpTypes; dont_dlopen=true),
    LibraryProduct("libimmiscibleIncompressibleTwoPhaseMixture", :libimmiscibleIncompressibleTwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libincompressibleInterPhaseTransportModels", :libincompressibleInterPhaseTransportModels; dont_dlopen=true),
    LibraryProduct("libincompressibleMultiphaseSystems", :libincompressibleMultiphaseSystems; dont_dlopen=true),
    LibraryProduct("libincompressibleTransportModels", :libincompressibleTransportModels; dont_dlopen=true),
    LibraryProduct("libincompressibleTurbulenceModels", :libincompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libinitialisationFunctionObjects", :libinitialisationFunctionObjects; dont_dlopen=true),
    LibraryProduct("libinterfaceProperties", :libinterfaceProperties; dont_dlopen=true),
    LibraryProduct("libinterfaceTrackingFvMesh", :libinterfaceTrackingFvMesh; dont_dlopen=true),
    LibraryProduct("libkahipDecomp", :libkahipDecomp; dont_dlopen=true),
    LibraryProduct("liblagrangian", :liblagrangian; dont_dlopen=true),
    LibraryProduct("liblagrangianFunctionObjects", :liblagrangianFunctionObjects; dont_dlopen=true),
    LibraryProduct("liblagrangianIntermediate", :liblagrangianIntermediate; dont_dlopen=true),
    LibraryProduct("liblagrangianSpray", :liblagrangianSpray; dont_dlopen=true),
    LibraryProduct("liblagrangianTurbulence", :liblagrangianTurbulence; dont_dlopen=true),
    LibraryProduct("liblaminarFlameSpeedModels", :liblaminarFlameSpeedModels; dont_dlopen=true),
    LibraryProduct("liblaserDTRM", :liblaserDTRM; dont_dlopen=true),
    LibraryProduct("liblumpedPointMotion", :liblumpedPointMotion; dont_dlopen=true),
    LibraryProduct("libmeshLibrary", :libmeshLibrary; dont_dlopen=true),
    LibraryProduct("libmeshTools", :libmeshTools; dont_dlopen=true),
    LibraryProduct("libmetisDecomp", :libmetisDecomp; dont_dlopen=true),
    LibraryProduct("libMGridGen", :libMGridGen; dont_dlopen=true),
    LibraryProduct("libmolecularMeasurements", :libmolecularMeasurements; dont_dlopen=true),
    LibraryProduct("libmolecule", :libmolecule; dont_dlopen=true),
    LibraryProduct("libmultiphaseInterFoam", :libmultiphaseInterFoam; dont_dlopen=true),
    LibraryProduct("libmultiphaseMixtureThermo", :libmultiphaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libmultiphaseSystem", :libmultiphaseSystem; dont_dlopen=true),
    LibraryProduct("libODE", :libODE; dont_dlopen=true),
    LibraryProduct("libOpenFOAM", :libOpenFOAM; dont_dlopen=true),
    LibraryProduct("liboverset", :liboverset; dont_dlopen=true),
    LibraryProduct("libpairPatchAgglomeration", :libpairPatchAgglomeration; dont_dlopen=true),
    LibraryProduct("libpdrFields", :libpdrFields; dont_dlopen=true),
    LibraryProduct("libphaseChangeTwoPhaseMixtures", :libphaseChangeTwoPhaseMixtures; dont_dlopen=true),
    LibraryProduct("libphaseCompressibleTurbulenceModels", :libphaseCompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libphaseFunctionObjects", :libphaseFunctionObjects; dont_dlopen=true),
    LibraryProduct("libphaseTemperatureChangeTwoPhaseMixtures", :libphaseTemperatureChangeTwoPhaseMixtures; dont_dlopen=true),
    LibraryProduct("libPolyhedronReader", :libPolyhedronReader; dont_dlopen=true),
    LibraryProduct("libpotential", :libpotential; dont_dlopen=true),
    LibraryProduct("libPstream", :libPstream; dont_dlopen=true),
    LibraryProduct("libptscotchDecomp", :libptscotchDecomp; dont_dlopen=true),
    LibraryProduct("libpyrolysisModels", :libpyrolysisModels; dont_dlopen=true),
    LibraryProduct("libradiationModels", :libradiationModels; dont_dlopen=true),
    LibraryProduct("librandomProcesses", :librandomProcesses; dont_dlopen=true),
    LibraryProduct("librandomProcessesFunctionObjects", :librandomProcessesFunctionObjects; dont_dlopen=true),
    LibraryProduct("libreactingMultiphaseSystem", :libreactingMultiphaseSystem; dont_dlopen=true),
    LibraryProduct("libreactingTwoPhaseSystem", :libreactingTwoPhaseSystem; dont_dlopen=true),
    LibraryProduct("libreactionThermophysicalModels", :libreactionThermophysicalModels; dont_dlopen=true),
    LibraryProduct("libreconstruct", :libreconstruct; dont_dlopen=true),
    LibraryProduct("libregionCoupling", :libregionCoupling; dont_dlopen=true),
    LibraryProduct("libregionFaModels", :libregionFaModels; dont_dlopen=true),
    LibraryProduct("libregionModels", :libregionModels; dont_dlopen=true),
    LibraryProduct("librenumberMethods", :librenumberMethods; dont_dlopen=true),
    LibraryProduct("librhoCentralFoam", :librhoCentralFoam; dont_dlopen=true),
    LibraryProduct("librigidBodyDynamics", :librigidBodyDynamics; dont_dlopen=true),
    LibraryProduct("librigidBodyMeshMotion", :librigidBodyMeshMotion; dont_dlopen=true),
    LibraryProduct("libsampling", :libsampling; dont_dlopen=true),
    LibraryProduct("libsaturationModel", :libsaturationModel; dont_dlopen=true),
    LibraryProduct("libscotchDecomp", :libscotchDecomp; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyMotion", :libsixDoFRigidBodyMotion; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyState", :libsixDoFRigidBodyState; dont_dlopen=true),
    LibraryProduct("libSLGThermo", :libSLGThermo; dont_dlopen=true),
    LibraryProduct("libSloanRenumber", :libSloanRenumber; dont_dlopen=true),
    LibraryProduct("libsnappyHexMesh", :libsnappyHexMesh; dont_dlopen=true),
    LibraryProduct("libsolidChemistryModel", :libsolidChemistryModel; dont_dlopen=true),
    LibraryProduct("libsolidParticle", :libsolidParticle; dont_dlopen=true),
    LibraryProduct("libsolidSpecie", :libsolidSpecie; dont_dlopen=true),
    LibraryProduct("libsolidThermo", :libsolidThermo; dont_dlopen=true),
    LibraryProduct("libsolverFunctionObjects", :libsolverFunctionObjects; dont_dlopen=true),
    LibraryProduct("libspecie", :libspecie; dont_dlopen=true),
    LibraryProduct("libsurfaceFeatureExtract", :libsurfaceFeatureExtract; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmDerivedFvPatchFields", :libsurfaceFilmDerivedFvPatchFields; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmModels", :libsurfaceFilmModels; dont_dlopen=true),
    LibraryProduct("libsurfMesh", :libsurfMesh; dont_dlopen=true),
    LibraryProduct("libtabulatedWallFunctions", :libtabulatedWallFunctions; dont_dlopen=true),
    LibraryProduct("libthermalBaffleModels", :libthermalBaffleModels; dont_dlopen=true),
    LibraryProduct("libthermophysicalProperties", :libthermophysicalProperties; dont_dlopen=true),
    LibraryProduct("libthermoTools", :libthermoTools; dont_dlopen=true),
    LibraryProduct("libtopoChangerFvMesh", :libtopoChangerFvMesh; dont_dlopen=true),
    LibraryProduct("libturbulenceModels", :libturbulenceModels; dont_dlopen=true),
    LibraryProduct("libturbulenceModelSchemes", :libturbulenceModelSchemes; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixture", :libtwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixtureThermo", :libtwoPhaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libtwoPhaseProperties", :libtwoPhaseProperties; dont_dlopen=true),
    LibraryProduct("libtwoPhaseReactingTurbulenceModels", :libtwoPhaseReactingTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libtwoPhaseSurfaceTension", :libtwoPhaseSurfaceTension; dont_dlopen=true),
    LibraryProduct("libutilityFunctionObjects", :libutilityFunctionObjects; dont_dlopen=true),
    LibraryProduct("libVoFphaseCompressibleTurbulenceModels", :libVoFphaseCompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libVoFphaseTurbulentTransportModels", :libVoFphaseTurbulentTransportModels; dont_dlopen=true),
    LibraryProduct("libwaveModels", :libwaveModels; dont_dlopen=true),
    
    ExecutableProduct("acousticFoam", :acousticFoam),
    ExecutableProduct("adiabaticFlameT", :adiabaticFlameT),
    ExecutableProduct("adjointOptimisationFoam", :adjointOptimisationFoam),
    ExecutableProduct("adjointShapeOptimizationFoam", :adjointShapeOptimizationFoam),
    ExecutableProduct("ansysToFoam", :ansysToFoam),
    ExecutableProduct("applyBoundaryLayer", :applyBoundaryLayer),
    ExecutableProduct("attachMesh", :attachMesh),
    ExecutableProduct("autoPatch", :autoPatch),
    ExecutableProduct("blockMesh", :blockMesh),
    ExecutableProduct("boundaryFoam", :boundaryFoam),
    ExecutableProduct("boxTurb", :boxTurb),
    ExecutableProduct("buoyantBoussinesqPimpleFoam", :buoyantBoussinesqPimpleFoam),
    ExecutableProduct("buoyantBoussinesqSimpleFoam", :buoyantBoussinesqSimpleFoam),
    ExecutableProduct("buoyantPimpleFoam", :buoyantPimpleFoam),
    ExecutableProduct("buoyantSimpleFoam", :buoyantSimpleFoam),
    ExecutableProduct("cartesian2DMesh", :cartesian2DMesh),
    ExecutableProduct("cartesianMesh", :cartesianMesh),
    ExecutableProduct("cavitatingDyMFoam", :cavitatingDyMFoam),
    ExecutableProduct("cavitatingFoam", :cavitatingFoam),
    ExecutableProduct("cfx4ToFoam", :cfx4ToFoam),
    ExecutableProduct("changeDictionary", :changeDictionary),
    ExecutableProduct("checkFaMesh", :checkFaMesh),
    ExecutableProduct("checkMesh", :checkMesh),
    ExecutableProduct("checkSurfaceMesh", :checkSurfaceMesh),
    ExecutableProduct("chemFoam", :chemFoam),
    ExecutableProduct("chemkinToFoam", :chemkinToFoam),
    ExecutableProduct("chtMultiRegionFoam", :chtMultiRegionFoam),
    ExecutableProduct("chtMultiRegionSimpleFoam", :chtMultiRegionSimpleFoam),
    ExecutableProduct("chtMultiRegionTwoPhaseEulerFoam", :chtMultiRegionTwoPhaseEulerFoam),
    ExecutableProduct("coalChemistryFoam", :coalChemistryFoam),
    ExecutableProduct("coldEngineFoam", :coldEngineFoam),
    ExecutableProduct("collapseEdges", :collapseEdges),
    ExecutableProduct("combinePatchFaces", :combinePatchFaces),
    ExecutableProduct("compressibleInterDyMFoam", :compressibleInterDyMFoam),
    ExecutableProduct("compressibleInterFilmFoam", :compressibleInterFilmFoam),
    ExecutableProduct("compressibleInterFoam", :compressibleInterFoam),
    ExecutableProduct("compressibleInterIsoFoam", :compressibleInterIsoFoam),
    ExecutableProduct("compressibleMultiphaseInterFoam", :compressibleMultiphaseInterFoam),
    ExecutableProduct("computeSensitivities", :computeSensitivities),
    ExecutableProduct("copySurfaceParts", :copySurfaceParts),
    ExecutableProduct("createBaffles", :createBaffles),
    ExecutableProduct("createBoxTurb", :createBoxTurb),
    ExecutableProduct("createExternalCoupledPatchGeometry", :createExternalCoupledPatchGeometry),
    ExecutableProduct("createPatch", :createPatch),
    ExecutableProduct("createROMfields", :createROMfields),
    ExecutableProduct("createZeroDirectory", :createZeroDirectory),
    ExecutableProduct("cumulativeDisplacement", :cumulativeDisplacement),
    ExecutableProduct("datToFoam", :datToFoam),
    ExecutableProduct("decomposePar", :decomposePar),
    ExecutableProduct("deformedGeom", :deformedGeom),
    ExecutableProduct("dnsFoam", :dnsFoam),
    ExecutableProduct("DPMDyMFoam", :DPMDyMFoam),
    ExecutableProduct("DPMFoam", :DPMFoam),
    ExecutableProduct("driftFluxFoam", :driftFluxFoam),
    ExecutableProduct("dsmcFoam", :dsmcFoam),
    ExecutableProduct("dsmcInitialise", :dsmcInitialise),
    ExecutableProduct("electrostaticFoam", :electrostaticFoam),
    ExecutableProduct("engineCompRatio", :engineCompRatio),
    ExecutableProduct("engineFoam", :engineFoam),
    ExecutableProduct("engineSwirl", :engineSwirl),
    ExecutableProduct("ensightToFoam", :ensightToFoam),
    ExecutableProduct("equilibriumCO", :equilibriumCO),
    ExecutableProduct("equilibriumFlameT", :equilibriumFlameT),
    ExecutableProduct("extrude2DMesh", :extrude2DMesh),
    ExecutableProduct("extrudeEdgesInto2DSurface", :extrudeEdgesInto2DSurface),
    ExecutableProduct("extrudeMesh", :extrudeMesh),
    ExecutableProduct("extrudeToRegionMesh", :extrudeToRegionMesh),
    ExecutableProduct("faceAgglomerate", :faceAgglomerate),
    ExecutableProduct("faParkerFukushimaFoam", :faParkerFukushimaFoam),
    ExecutableProduct("faSavageHutterFoam", :faSavageHutterFoam),
    ExecutableProduct("faTwoLayerAvalancheFoam", :faTwoLayerAvalancheFoam),
    ExecutableProduct("financialFoam", :financialFoam),
    ExecutableProduct("fireFoam", :fireFoam),
    ExecutableProduct("fireToFoam", :fireToFoam),
    ExecutableProduct("flattenMesh", :flattenMesh),
    ExecutableProduct("FLMAToSurface", :FLMAToSurface),
    ExecutableProduct("fluent3DMeshToFoam", :fluent3DMeshToFoam),
    ExecutableProduct("fluentMeshToFoam", :fluentMeshToFoam),
    ExecutableProduct("FMSToSurface", :FMSToSurface),
    ExecutableProduct("FMSToVTK", :FMSToVTK),
    ExecutableProduct("foamDataToFluent", :foamDataToFluent),
    ExecutableProduct("foamDictionary", :foamDictionary),
    ExecutableProduct("foamFormatConvert", :foamFormatConvert),
    ExecutableProduct("foamHasLibrary", :foamHasLibrary),
    ExecutableProduct("foamHelp", :foamHelp),
    ExecutableProduct("foamListRegions", :foamListRegions),
    ExecutableProduct("foamListTimes", :foamListTimes),
    ExecutableProduct("foamMeshToFluent", :foamMeshToFluent),
    ExecutableProduct("foamRestoreFields", :foamRestoreFields),
    ExecutableProduct("foamToEnsight", :foamToEnsight),
    ExecutableProduct("foamToFireMesh", :foamToFireMesh),
    ExecutableProduct("foamToGMV", :foamToGMV),
    ExecutableProduct("foamToStarMesh", :foamToStarMesh),
    ExecutableProduct("foamToSurface", :foamToSurface),
    ExecutableProduct("foamToTetDualMesh", :foamToTetDualMesh),
    ExecutableProduct("foamToVTK", :foamToVTK),
    ExecutableProduct("foamUpgradeCyclics", :foamUpgradeCyclics),
    ExecutableProduct("foamyHexMesh", :foamyHexMesh),
    ExecutableProduct("foamyQuadMesh", :foamyQuadMesh),
    ExecutableProduct("gambitToFoam", :gambitToFoam),
    ExecutableProduct("generateBoundaryLayers", :generateBoundaryLayers),
    ExecutableProduct("gmshToFoam", :gmshToFoam),
    ExecutableProduct("gridToSTL", :gridToSTL),
    ExecutableProduct("icoFoam", :icoFoam),
    ExecutableProduct("icoReactingMultiphaseInterFoam", :icoReactingMultiphaseInterFoam),
    ExecutableProduct("icoUncoupledKinematicParcelDyMFoam", :icoUncoupledKinematicParcelDyMFoam),
    ExecutableProduct("icoUncoupledKinematicParcelFoam", :icoUncoupledKinematicParcelFoam),
    ExecutableProduct("ideasUnvToFoam", :ideasUnvToFoam),
    ExecutableProduct("importSurfaceAsSubset", :importSurfaceAsSubset),
    ExecutableProduct("improveMeshQuality", :improveMeshQuality),
    ExecutableProduct("improveSymmetryPlanes", :improveSymmetryPlanes),
    ExecutableProduct("insideCells", :insideCells),
    ExecutableProduct("interCondensatingEvaporatingFoam", :interCondensatingEvaporatingFoam),
    ExecutableProduct("interFoam", :interFoam),
    ExecutableProduct("interIsoFoam", :interIsoFoam),
    ExecutableProduct("interMixingFoam", :interMixingFoam),
    ExecutableProduct("interPhaseChangeDyMFoam", :interPhaseChangeDyMFoam),
    ExecutableProduct("interPhaseChangeFoam", :interPhaseChangeFoam),
    ExecutableProduct("kinematicParcelFoam", :kinematicParcelFoam),
    ExecutableProduct("kivaToFoam", :kivaToFoam),
    ExecutableProduct("laplacianFoam", :laplacianFoam),
    ExecutableProduct("liquidFilmFoam", :liquidFilmFoam),
    ExecutableProduct("lumpedPointForces", :lumpedPointForces),
    ExecutableProduct("lumpedPointMovement", :lumpedPointMovement),
    ExecutableProduct("lumpedPointZones", :lumpedPointZones),
    ExecutableProduct("magneticFoam", :magneticFoam),
    ExecutableProduct("makeFaMesh", :makeFaMesh),
    ExecutableProduct("mapFields", :mapFields),
    ExecutableProduct("mapFieldsPar", :mapFieldsPar),
    ExecutableProduct("mdEquilibrationFoam", :mdEquilibrationFoam),
    ExecutableProduct("mdFoam", :mdFoam),
    ExecutableProduct("mdInitialise", :mdInitialise),
    ExecutableProduct("mergeMeshes", :mergeMeshes),
    ExecutableProduct("mergeOrSplitBaffles", :mergeOrSplitBaffles),
    ExecutableProduct("mergeSurfacePatches", :mergeSurfacePatches),
    ExecutableProduct("meshToFPMA", :meshToFPMA),
    ExecutableProduct("mhdFoam", :mhdFoam),
    ExecutableProduct("mirrorMesh", :mirrorMesh),
    ExecutableProduct("mixtureAdiabaticFlameT", :mixtureAdiabaticFlameT),
    ExecutableProduct("modifyMesh", :modifyMesh),
    ExecutableProduct("moveDynamicMesh", :moveDynamicMesh),
    ExecutableProduct("moveEngineMesh", :moveEngineMesh),
    ExecutableProduct("moveMesh", :moveMesh),
    ExecutableProduct("MPPICDyMFoam", :MPPICDyMFoam),
    ExecutableProduct("MPPICFoam", :MPPICFoam),
    ExecutableProduct("MPPICInterFoam", :MPPICInterFoam),
    ExecutableProduct("mshToFoam", :mshToFoam),
    ExecutableProduct("multiphaseEulerFoam", :multiphaseEulerFoam),
    ExecutableProduct("multiphaseInterFoam", :multiphaseInterFoam),
    ExecutableProduct("netgenNeutralToFoam", :netgenNeutralToFoam),
    ExecutableProduct("noise", :noise),
    ExecutableProduct("nonNewtonianIcoFoam", :nonNewtonianIcoFoam),
    ExecutableProduct("objToVTK", :objToVTK),
    ExecutableProduct("orientFaceZone", :orientFaceZone),
    ExecutableProduct("overBuoyantPimpleDyMFoam", :overBuoyantPimpleDyMFoam),
    ExecutableProduct("overCompressibleInterDyMFoam", :overCompressibleInterDyMFoam),
    ExecutableProduct("overInterDyMFoam", :overInterDyMFoam),
    ExecutableProduct("overInterPhaseChangeDyMFoam", :overInterPhaseChangeDyMFoam),
    ExecutableProduct("overLaplacianDyMFoam", :overLaplacianDyMFoam),
    ExecutableProduct("overPimpleDyMFoam", :overPimpleDyMFoam),
    ExecutableProduct("overPotentialFoam", :overPotentialFoam),
    ExecutableProduct("overRhoPimpleDyMFoam", :overRhoPimpleDyMFoam),
    ExecutableProduct("overRhoSimpleFoam", :overRhoSimpleFoam),
    ExecutableProduct("overSimpleFoam", :overSimpleFoam),
    ExecutableProduct("particleTracks", :particleTracks),
    ExecutableProduct("patchesToSubsets", :patchesToSubsets),
    ExecutableProduct("patchSummary", :patchSummary),
    ExecutableProduct("pdfPlot", :pdfPlot),
    ExecutableProduct("PDRblockMesh", :PDRblockMesh),
    ExecutableProduct("PDRFoam", :PDRFoam),
    ExecutableProduct("PDRMesh", :PDRMesh),
    ExecutableProduct("PDRsetFields", :PDRsetFields),
    ExecutableProduct("pimpleFoam", :pimpleFoam),
    ExecutableProduct("pisoFoam", :pisoFoam),
    ExecutableProduct("plot3dToFoam", :plot3dToFoam),
    ExecutableProduct("pMesh", :pMesh),
    ExecutableProduct("polyDualMesh", :polyDualMesh),
    ExecutableProduct("porousSimpleFoam", :porousSimpleFoam),
    ExecutableProduct("postChannel", :postChannel),
    ExecutableProduct("postProcess", :postProcess),
    ExecutableProduct("potentialFoam", :potentialFoam),
    ExecutableProduct("potentialFreeSurfaceDyMFoam", :potentialFreeSurfaceDyMFoam),
    ExecutableProduct("potentialFreeSurfaceFoam", :potentialFreeSurfaceFoam),
    ExecutableProduct("preparePar", :preparePar),
    ExecutableProduct("profilingSummary", :profilingSummary),
    ExecutableProduct("reactingFoam", :reactingFoam),
    ExecutableProduct("reactingHeterogenousParcelFoam", :reactingHeterogenousParcelFoam),
    ExecutableProduct("reactingMultiphaseEulerFoam", :reactingMultiphaseEulerFoam),
    ExecutableProduct("reactingParcelFoam", :reactingParcelFoam),
    ExecutableProduct("reactingTwoPhaseEulerFoam", :reactingTwoPhaseEulerFoam),
    ExecutableProduct("reconstructPar", :reconstructPar),
    ExecutableProduct("reconstructParMesh", :reconstructParMesh),
    ExecutableProduct("redistributePar", :redistributePar),
    ExecutableProduct("refineHexMesh", :refineHexMesh),
    ExecutableProduct("refinementLevel", :refinementLevel),
    ExecutableProduct("refineMesh", :refineMesh),
    ExecutableProduct("refineWallLayer", :refineWallLayer),
    ExecutableProduct("releaseAreaMapping", :releaseAreaMapping),
    ExecutableProduct("removeFaces", :removeFaces),
    ExecutableProduct("removeSurfaceFacets", :removeSurfaceFacets),
    ExecutableProduct("renumberMesh", :renumberMesh),
    ExecutableProduct("rhoCentralFoam", :rhoCentralFoam),
    ExecutableProduct("rhoPimpleAdiabaticFoam", :rhoPimpleAdiabaticFoam),
    ExecutableProduct("rhoPimpleFoam", :rhoPimpleFoam),
    ExecutableProduct("rhoPorousSimpleFoam", :rhoPorousSimpleFoam),
    ExecutableProduct("rhoReactingBuoyantFoam", :rhoReactingBuoyantFoam),
    ExecutableProduct("rhoReactingFoam", :rhoReactingFoam),
    ExecutableProduct("rhoSimpleFoam", :rhoSimpleFoam),
    ExecutableProduct("rotateMesh", :rotateMesh),
    ExecutableProduct("scalarTransportFoam", :scalarTransportFoam),
    ExecutableProduct("scaleMesh", :scaleMesh),
    ExecutableProduct("scaleSurfaceMesh", :scaleSurfaceMesh),
    ExecutableProduct("selectCells", :selectCells),
    ExecutableProduct("setAlphaField", :setAlphaField),
    ExecutableProduct("setExprBoundaryFields", :setExprBoundaryFields),
    ExecutableProduct("setExprFields", :setExprFields),
    ExecutableProduct("setFields", :setFields),
    ExecutableProduct("setSet", :setSet),
    ExecutableProduct("setsToZones", :setsToZones),
    ExecutableProduct("setTurbulenceFields", :setTurbulenceFields),
    ExecutableProduct("shallowWaterFoam", :shallowWaterFoam),
    ExecutableProduct("simpleCoalParcelFoam", :simpleCoalParcelFoam),
    ExecutableProduct("simpleFoam", :simpleFoam),
    ExecutableProduct("simpleReactingParcelFoam", :simpleReactingParcelFoam),
    ExecutableProduct("simpleSprayFoam", :simpleSprayFoam),
    ExecutableProduct("singleCellMesh", :singleCellMesh),
    ExecutableProduct("slopeMesh", :slopeMesh),
    ExecutableProduct("smapToFoam", :smapToFoam),
    ExecutableProduct("smoothSurfaceData", :smoothSurfaceData),
    ExecutableProduct("snappyHexMesh", :snappyHexMesh),
    ExecutableProduct("snappyRefineMesh", :snappyRefineMesh),
    ExecutableProduct("solidDisplacementFoam", :solidDisplacementFoam),
    ExecutableProduct("solidEquilibriumDisplacementFoam", :solidEquilibriumDisplacementFoam),
    ExecutableProduct("solidFoam", :solidFoam),
    ExecutableProduct("sonicDyMFoam", :sonicDyMFoam),
    ExecutableProduct("sonicFoam", :sonicFoam),
    ExecutableProduct("sonicLiquidFoam", :sonicLiquidFoam),
    ExecutableProduct("sphereSurfactantFoam", :sphereSurfactantFoam),
    ExecutableProduct("splitCells", :splitCells),
    ExecutableProduct("splitMesh", :splitMesh),
    ExecutableProduct("splitMeshRegions", :splitMeshRegions),
    ExecutableProduct("sprayDyMFoam", :sprayDyMFoam),
    ExecutableProduct("sprayFoam", :sprayFoam),
    ExecutableProduct("SRFPimpleFoam", :SRFPimpleFoam),
    ExecutableProduct("SRFSimpleFoam", :SRFSimpleFoam),
    ExecutableProduct("star4ToFoam", :star4ToFoam),
    ExecutableProduct("steadyParticleTracks", :steadyParticleTracks),
    ExecutableProduct("stitchMesh", :stitchMesh),
    ExecutableProduct("subsetMesh", :subsetMesh),
    ExecutableProduct("subsetToPatch", :subsetToPatch),
    ExecutableProduct("surfaceAdd", :surfaceAdd),
    ExecutableProduct("surfaceBooleanFeatures", :surfaceBooleanFeatures),
    ExecutableProduct("surfaceCheck", :surfaceCheck),
    ExecutableProduct("surfaceClean", :surfaceClean),
    ExecutableProduct("surfaceCoarsen", :surfaceCoarsen),
    ExecutableProduct("surfaceConvert", :surfaceConvert),
    ExecutableProduct("surfaceFeatureConvert", :surfaceFeatureConvert),
    ExecutableProduct("surfaceFeatureEdges", :surfaceFeatureEdges),
    ExecutableProduct("surfaceFeatureExtract", :surfaceFeatureExtract),
    ExecutableProduct("surfaceFind", :surfaceFind),
    ExecutableProduct("surfaceGenerateBoundingBox", :surfaceGenerateBoundingBox),
    ExecutableProduct("surfaceHookUp", :surfaceHookUp),
    ExecutableProduct("surfaceInertia", :surfaceInertia),
    ExecutableProduct("surfaceInflate", :surfaceInflate),
    ExecutableProduct("surfaceLambdaMuSmooth", :surfaceLambdaMuSmooth),
    ExecutableProduct("surfaceMeshConvert", :surfaceMeshConvert),
    ExecutableProduct("surfaceMeshExport", :surfaceMeshExport),
    ExecutableProduct("surfaceMeshExtract", :surfaceMeshExtract),
    ExecutableProduct("surfaceMeshImport", :surfaceMeshImport),
    ExecutableProduct("surfaceMeshInfo", :surfaceMeshInfo),
    ExecutableProduct("surfaceOrient", :surfaceOrient),
    ExecutableProduct("surfacePatch", :surfacePatch),
    ExecutableProduct("surfacePointMerge", :surfacePointMerge),
    ExecutableProduct("surfaceRedistributePar", :surfaceRedistributePar),
    ExecutableProduct("surfaceRefineRedGreen", :surfaceRefineRedGreen),
    ExecutableProduct("surfaceSplitByPatch", :surfaceSplitByPatch),
    ExecutableProduct("surfaceSplitByTopology", :surfaceSplitByTopology),
    ExecutableProduct("surfaceSplitNonManifolds", :surfaceSplitNonManifolds),
    ExecutableProduct("surfaceSubset", :surfaceSubset),
    ExecutableProduct("surfaceToFMS", :surfaceToFMS),
    ExecutableProduct("surfaceToPatch", :surfaceToPatch),
    ExecutableProduct("surfaceTransformPoints", :surfaceTransformPoints),
    ExecutableProduct("surfactantFoam", :surfactantFoam),
    ExecutableProduct("temporalInterpolate", :temporalInterpolate),
    ExecutableProduct("tetgenToFoam", :tetgenToFoam),
    ExecutableProduct("tetMesh", :tetMesh),
    ExecutableProduct("thermoFoam", :thermoFoam),
    ExecutableProduct("topoSet", :topoSet),
    ExecutableProduct("transformPoints", :transformPoints),
    ExecutableProduct("twoLiquidMixingFoam", :twoLiquidMixingFoam),
    ExecutableProduct("twoPhaseEulerFoam", :twoPhaseEulerFoam),
    ExecutableProduct("uncoupledKinematicParcelDyMFoam", :uncoupledKinematicParcelDyMFoam),
    ExecutableProduct("uncoupledKinematicParcelFoam", :uncoupledKinematicParcelFoam),
    ExecutableProduct("viewFactorsGen", :viewFactorsGen),
    ExecutableProduct("vtkUnstructuredToFoam", :vtkUnstructuredToFoam),
    ExecutableProduct("wallFunctionTable", :wallFunctionTable),
    ExecutableProduct("writeMeshObj", :writeMeshObj),
    ExecutableProduct("writeMorpherCPs", :writeMorpherCPs),
    ExecutableProduct("XiDyMFoam", :XiDyMFoam),
    ExecutableProduct("XiEngineFoam", :XiEngineFoam),
    ExecutableProduct("XiFoam", :XiFoam),
    ExecutableProduct("zipUpMesh", :zipUpMesh),
    
    FileProduct("etc", :openfoam_etc), 
]

init_block = raw"""ENV["WM_PROJECT_DIR"] = artifact_dir"""
# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
    BuildDependency(PackageSpec(name="CGAL_jll", uuid="8fcd9439-76b0-55f4-a525-bad0597c05d8"))
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"); compat=SCOTCH_VERSION)
    Dependency(PackageSpec(name="FFTW_jll", uuid="f5851436-0d7a-5f13-b9de-f02708fd171a"); compat=FFTW_VERSION)
    Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"))
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version = v"9", init_block)
