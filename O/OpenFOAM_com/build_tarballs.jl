# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenFOAM_com"
version = v"2312.0.0"
openfoam_version=v"2312"

# Collection of sources required to complete build
sources = [
    GitSource("https://develop.openfoam.com/Development/openfoam.git", "1d8f0d55f79e6488dae75e4b839e358a88af77b5"),
    DirectorySource("./bundled")
]

# In order to set up OpenFOAM, we need to know the version of some of the
# dependencies.
const SCOTCH_VERSION = "6.1.3"

# Bash recipe for building across all platforms
script = "SCOTCH_VERSION=$(SCOTCH_VERSION)\n" * raw"""

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/bashrc-compilerflags.patch

cd ${WORKSPACE}/srcdir/openfoam

# Set rpath-link in all C/C++ compilers for Linux64
LDFLAGS=""
for dir in "" "/dummy" "/sys-mpi"; do     
LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"; 
done

# Set version of Scotch
echo "export SCOTCH_VERSION=${SCOTCH_VERSION}" > etc/config.sh/scotch
echo "export SCOTCH_ARCH_PATH=${prefix}"      >> etc/config.sh/scotch

# Setup to use our MPI
sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/g' etc/bashrc
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
mkdir -p "${libdir}" "${bindir}" "${prefix}/share/openfoam"
cp platforms/linux64GccDPInt32Opt/lib/{,dummy/,sys-mpi/}*.${dlext}* "${libdir}/."
cp platforms/linux64GccDPInt32Opt/bin/* "${bindir}/."
cp -r etc/ "${prefix}/share/openfoam/."
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
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libengine", :libengine),
    LibraryProduct("libdistributionModels", :libdistributionModels),
    LibraryProduct("libtwoPhaseReactingTurbulenceModels", :libtwoPhaseReactingTurbulenceModels),
    LibraryProduct("libfiniteArea", :libfiniteArea),
    LibraryProduct("libmultiphaseSystem", :libmultiphaseSystem),
    LibraryProduct("libcompressibleTurbulenceModels", :libcompressibleTurbulenceModels),
    LibraryProduct("libsaturationModel", :libsaturationModel),
    LibraryProduct("libsurfMesh", :libsurfMesh),
    LibraryProduct("liblagrangianIntermediate", :liblagrangianIntermediate),
    LibraryProduct("libthermoTools", :libthermoTools),
    LibraryProduct("libsurfaceFilmDerivedFvPatchFields", :libsurfaceFilmDerivedFvPatchFields),
    LibraryProduct("libreactingMultiphaseSystem", :libreactingMultiphaseSystem),
    LibraryProduct("libmeshTools", :libmeshTools),
    LibraryProduct("libptscotchDecomp", :libptscotchDecomp),
    LibraryProduct("libdecompositionMethods", :libdecompositionMethods),
    LibraryProduct("libconversion", :libconversion),
    LibraryProduct("libincompressibleMultiphaseSystems", :libincompressibleMultiphaseSystems),
    LibraryProduct("libfaDecompose", :libfaDecompose),
    LibraryProduct("libincompressibleTransportModels", :libincompressibleTransportModels),
    LibraryProduct("libtwoPhaseMixture", :libtwoPhaseMixture),
    LibraryProduct("libsolverFunctionObjects", :libsolverFunctionObjects),
    LibraryProduct("libinterfaceProperties", :libinterfaceProperties),
    LibraryProduct("libfvMotionSolvers", :libfvMotionSolvers),
    LibraryProduct("libtabulatedWallFunctions", :libtabulatedWallFunctions),
    LibraryProduct("libtwoPhaseMixtureThermo", :libtwoPhaseMixtureThermo),
    LibraryProduct("libregionFaModels", :libregionFaModels),
    LibraryProduct("libsampling", :libsampling),
    LibraryProduct("libalphaFieldFunctions", :libalphaFieldFunctions),
    LibraryProduct("liblagrangianSpray", :liblagrangianSpray),
    LibraryProduct("liblagrangian", :liblagrangian),
    LibraryProduct("libinitialisationFunctionObjects", :libinitialisationFunctionObjects),
    LibraryProduct("libDSMC", :libDSMC),
    LibraryProduct("libfileFormats", :libfileFormats),
    LibraryProduct("libimmiscibleIncompressibleTwoPhaseMixture", :libimmiscibleIncompressibleTwoPhaseMixture),
    LibraryProduct("libMGridGen", :libMGridGen),
    LibraryProduct("libinterfaceTrackingFvMesh", :libinterfaceTrackingFvMesh),
    LibraryProduct("libmolecularMeasurements", :libmolecularMeasurements),
    LibraryProduct("librenumberMethods", :librenumberMethods),
    LibraryProduct("libhelpTypes", :libhelpTypes),
    LibraryProduct("libtwoPhaseProperties", :libtwoPhaseProperties),
    LibraryProduct("libchemistryModel", :libchemistryModel),
    LibraryProduct("libfvOptions", :libfvOptions),
    LibraryProduct("libdynamicMesh", :libdynamicMesh),
    LibraryProduct("libkahipDecomp", :libkahipDecomp),
    LibraryProduct("libspecie", :libspecie),
    LibraryProduct("libturbulenceModels", :libturbulenceModels),
    LibraryProduct("libdriftFluxRelativeVelocityModels", :libdriftFluxRelativeVelocityModels),
    LibraryProduct("libpotential", :libpotential),
    LibraryProduct("libphaseFunctionObjects", :libphaseFunctionObjects),
    LibraryProduct("liblaminarFlameSpeedModels", :liblaminarFlameSpeedModels),
    LibraryProduct("libpairPatchAgglomeration", :libpairPatchAgglomeration),
    LibraryProduct("libgenericPatchFields", :libgenericPatchFields),
    LibraryProduct("libdecompose", :libdecompose),
    LibraryProduct("libreactionThermophysicalModels", :libreactionThermophysicalModels),
    LibraryProduct("libSLGThermo", :libSLGThermo),
    LibraryProduct("libfiniteVolume", :libfiniteVolume),
    LibraryProduct("libturbulenceModelSchemes", :libturbulenceModelSchemes),
    LibraryProduct("libfaOptions", :libfaOptions),
    LibraryProduct("libextrudeModel", :libextrudeModel),
    LibraryProduct("libregionModels", :libregionModels),
    LibraryProduct("libsolidSpecie", :libsolidSpecie),
    LibraryProduct("liblagrangianTurbulence", :liblagrangianTurbulence),
    LibraryProduct("libincompressibleInterPhaseTransportModels", :libincompressibleInterPhaseTransportModels),
    LibraryProduct("librigidBodyDynamics", :librigidBodyDynamics),
    LibraryProduct("libDPMTurbulenceModels", :libDPMTurbulenceModels),
    LibraryProduct("libPstream", :libPstream),
    LibraryProduct("libsolidChemistryModel", :libsolidChemistryModel),
    LibraryProduct("libcompressibleMultiPhaseTurbulenceModels", :libcompressibleMultiPhaseTurbulenceModels),
    LibraryProduct("liblaserDTRM", :liblaserDTRM),
    LibraryProduct("libVoFphaseCompressibleTurbulenceModels", :libVoFphaseCompressibleTurbulenceModels),
    LibraryProduct("liblumpedPointMotion", :liblumpedPointMotion),
    LibraryProduct("libmolecule", :libmolecule),
    LibraryProduct("libOpenFOAM", :libOpenFOAM),
    LibraryProduct("libcompressibleTransportModels", :libcompressibleTransportModels),
    LibraryProduct("librigidBodyMeshMotion", :librigidBodyMeshMotion),
    LibraryProduct("libfaReconstruct", :libfaReconstruct),
    LibraryProduct("libthermophysicalProperties", :libthermophysicalProperties),
    LibraryProduct("libwaveModels", :libwaveModels),
    LibraryProduct("libsolidParticle", :libsolidParticle),
    LibraryProduct("libradiationModels", :libradiationModels),
    LibraryProduct("libcompressibleTwoPhaseMixtureTurbulenceModels", :libcompressibleTwoPhaseMixtureTurbulenceModels),
    LibraryProduct("libpdrFields", :libpdrFields),
    LibraryProduct("libsolidThermo", :libsolidThermo),
    LibraryProduct("libfieldFunctionObjects", :libfieldFunctionObjects),
    LibraryProduct("libdynamicFvMesh", :libdynamicFvMesh),
    LibraryProduct("libreconstruct", :libreconstruct),
    LibraryProduct("libdistributed", :libdistributed),
    LibraryProduct("libreactingTwoPhaseSystem", :libreactingTwoPhaseSystem),
    LibraryProduct("libthermalBaffleModels", :libthermalBaffleModels),
    LibraryProduct("libscotchDecomp", :libscotchDecomp),
    LibraryProduct("libphaseChangeTwoPhaseMixtures", :libphaseChangeTwoPhaseMixtures),
    LibraryProduct("libmultiphaseMixtureThermo", :libmultiphaseMixtureThermo),
    LibraryProduct("libVoFphaseTurbulentTransportModels", :libVoFphaseTurbulentTransportModels),
    LibraryProduct("libcoalCombustion", :libcoalCombustion),
    LibraryProduct("liblagrangianFunctionObjects", :liblagrangianFunctionObjects),
    LibraryProduct("libforces", :libforces),
    LibraryProduct("libcombustionModels", :libcombustionModels),
    LibraryProduct("libphaseTemperatureChangeTwoPhaseMixtures", :libphaseTemperatureChangeTwoPhaseMixtures),
    LibraryProduct("libextrude2DMesh", :libextrude2DMesh),
    LibraryProduct("libregionCoupling", :libregionCoupling),
    LibraryProduct("libODE", :libODE),
    LibraryProduct("libcompressibleTwoPhaseSystem", :libcompressibleTwoPhaseSystem),
    LibraryProduct("libgeometricVoF", :libgeometricVoF),
    LibraryProduct("libtopoChangerFvMesh", :libtopoChangerFvMesh),
    LibraryProduct("libdriftFluxTransportModels", :libdriftFluxTransportModels),
    LibraryProduct("libadjointOptimisation", :libadjointOptimisation),
    LibraryProduct("libutilityFunctionObjects", :libutilityFunctionObjects),
    LibraryProduct("libtwoPhaseSurfaceTension", :libtwoPhaseSurfaceTension),
    LibraryProduct("libatmosphericModels", :libatmosphericModels),
    LibraryProduct("libsurfaceFeatureExtract", :libsurfaceFeatureExtract),
    LibraryProduct("libbarotropicCompressibilityModel", :libbarotropicCompressibilityModel),
    LibraryProduct("libsnappyHexMesh", :libsnappyHexMesh),
    LibraryProduct("librhoCentralFoam", :librhoCentralFoam),
    LibraryProduct("libphaseCompressibleTurbulenceModels", :libphaseCompressibleTurbulenceModels),
    LibraryProduct("libmultiphaseInterFoam", :libmultiphaseInterFoam),
    LibraryProduct("libblockMesh", :libblockMesh),
    LibraryProduct("liboverset", :liboverset),
    LibraryProduct("libsurfaceFilmModels", :libsurfaceFilmModels),
    LibraryProduct("libsixDoFRigidBodyMotion", :libsixDoFRigidBodyMotion),
    LibraryProduct("libmetisDecomp", :libmetisDecomp),
    LibraryProduct("libsixDoFRigidBodyState", :libsixDoFRigidBodyState),
    LibraryProduct("libpyrolysisModels", :libpyrolysisModels),
    LibraryProduct("libincompressibleTurbulenceModels", :libincompressibleTurbulenceModels),
    LibraryProduct("libfluidThermophysicalModels", :libfluidThermophysicalModels),
    ExecutableProduct("cumulativeDisplacement", :cumulativeDisplacement),
    ExecutableProduct("chemFoam", :chemFoam),
    ExecutableProduct("driftFluxFoam", :driftFluxFoam),
    ExecutableProduct("stitchMesh", :stitchMesh),
    ExecutableProduct("ensightToFoam", :ensightToFoam),
    ExecutableProduct("splitMeshRegions", :splitMeshRegions),
    ExecutableProduct("faceAgglomerate", :faceAgglomerate),
    ExecutableProduct("surfactantFoam", :surfactantFoam),
    ExecutableProduct("lumpedPointForces", :lumpedPointForces),
    ExecutableProduct("kivaToFoam", :kivaToFoam),
    ExecutableProduct("rhoSimpleFoam", :rhoSimpleFoam),
    ExecutableProduct("foamListTimes", :foamListTimes),
    ExecutableProduct("reactingParcelFoam", :reactingParcelFoam),
    ExecutableProduct("solidEquilibriumDisplacementFoam", :solidEquilibriumDisplacementFoam),
    ExecutableProduct("wallFunctionTable", :wallFunctionTable),
    ExecutableProduct("surfacePointMerge", :surfacePointMerge),
    ExecutableProduct("rhoReactingBuoyantFoam", :rhoReactingBuoyantFoam),
    ExecutableProduct("surfaceCheck", :surfaceCheck),
    ExecutableProduct("removeFaces", :removeFaces),
    ExecutableProduct("XiDyMFoam", :XiDyMFoam),
    ExecutableProduct("fireFoam", :fireFoam),
    ExecutableProduct("blockMesh", :blockMesh),
    ExecutableProduct("kinematicParcelFoam", :kinematicParcelFoam),
    ExecutableProduct("writeMeshObj", :writeMeshObj),
    ExecutableProduct("coldEngineFoam", :coldEngineFoam),
    ExecutableProduct("equilibriumCO", :equilibriumCO),
    ExecutableProduct("foamFormatConvert", :foamFormatConvert),
    ExecutableProduct("modifyMesh", :modifyMesh),
    ExecutableProduct("mergeMeshes", :mergeMeshes),
    ExecutableProduct("flattenMesh", :flattenMesh),
    ExecutableProduct("redistributePar", :redistributePar),
    ExecutableProduct("extrudeMesh", :extrudeMesh),
    ExecutableProduct("engineSwirl", :engineSwirl),
    ExecutableProduct("ideasUnvToFoam", :ideasUnvToFoam),
    ExecutableProduct("deformedGeom", :deformedGeom),
    ExecutableProduct("solidFoam", :solidFoam),
    ExecutableProduct("buoyantBoussinesqSimpleFoam", :buoyantBoussinesqSimpleFoam),
    ExecutableProduct("sonicLiquidFoam", :sonicLiquidFoam),
    ExecutableProduct("mhdFoam", :mhdFoam),
    ExecutableProduct("lumpedPointMovement", :lumpedPointMovement),
    ExecutableProduct("icoReactingMultiphaseInterFoam", :icoReactingMultiphaseInterFoam),
    ExecutableProduct("fluentMeshToFoam", :fluentMeshToFoam),
    ExecutableProduct("surfaceFind", :surfaceFind),
    ExecutableProduct("setsToZones", :setsToZones),
    ExecutableProduct("overBuoyantPimpleDyMFoam", :overBuoyantPimpleDyMFoam),
    ExecutableProduct("multiphaseEulerFoam", :multiphaseEulerFoam),
    ExecutableProduct("nonNewtonianIcoFoam", :nonNewtonianIcoFoam),
    ExecutableProduct("surfaceAdd", :surfaceAdd),
    ExecutableProduct("interIsoFoam", :interIsoFoam),
    ExecutableProduct("compressibleInterFoam", :compressibleInterFoam),
    ExecutableProduct("datToFoam", :datToFoam),
    ExecutableProduct("patchSummary", :patchSummary),
    ExecutableProduct("surfaceSplitNonManifolds", :surfaceSplitNonManifolds),
    ExecutableProduct("reconstructPar", :reconstructPar),
    ExecutableProduct("mixtureAdiabaticFlameT", :mixtureAdiabaticFlameT),
    ExecutableProduct("surfaceMeshImport", :surfaceMeshImport),
    ExecutableProduct("surfaceTransformPoints", :surfaceTransformPoints),
    ExecutableProduct("fluent3DMeshToFoam", :fluent3DMeshToFoam),
    ExecutableProduct("moveMesh", :moveMesh),
    ExecutableProduct("extrudeToRegionMesh", :extrudeToRegionMesh),
    ExecutableProduct("twoPhaseEulerFoam", :twoPhaseEulerFoam),
    ExecutableProduct("rhoReactingFoam", :rhoReactingFoam),
    ExecutableProduct("temporalInterpolate", :temporalInterpolate),
    ExecutableProduct("DPMDyMFoam", :DPMDyMFoam),
    ExecutableProduct("netgenNeutralToFoam", :netgenNeutralToFoam),
    ExecutableProduct("autoPatch", :autoPatch),
    ExecutableProduct("pimpleFoam", :pimpleFoam),
    ExecutableProduct("surfaceMeshExtract", :surfaceMeshExtract),
    ExecutableProduct("solidDisplacementFoam", :solidDisplacementFoam),
    ExecutableProduct("checkFaMesh", :checkFaMesh),
    ExecutableProduct("coalChemistryFoam", :coalChemistryFoam),
    ExecutableProduct("laplacianFoam", :laplacianFoam),
    ExecutableProduct("surfaceHookUp", :surfaceHookUp),
    ExecutableProduct("surfaceSplitByPatch", :surfaceSplitByPatch),
    ExecutableProduct("thermoFoam", :thermoFoam),
    ExecutableProduct("reactingFoam", :reactingFoam),
    ExecutableProduct("overCompressibleInterDyMFoam", :overCompressibleInterDyMFoam),
    ExecutableProduct("MPPICInterFoam", :MPPICInterFoam),
    ExecutableProduct("createZeroDirectory", :createZeroDirectory),
    ExecutableProduct("liquidFilmFoam", :liquidFilmFoam),
    ExecutableProduct("writeMorpherCPs", :writeMorpherCPs),
    ExecutableProduct("multiphaseInterFoam", :multiphaseInterFoam),
    ExecutableProduct("lumpedPointZones", :lumpedPointZones),
    ExecutableProduct("compressibleInterFilmFoam", :compressibleInterFilmFoam),
    ExecutableProduct("overLaplacianDyMFoam", :overLaplacianDyMFoam),
    ExecutableProduct("porousSimpleFoam", :porousSimpleFoam),
    ExecutableProduct("star4ToFoam", :star4ToFoam),
    ExecutableProduct("refinementLevel", :refinementLevel),
    ExecutableProduct("buoyantSimpleFoam", :buoyantSimpleFoam),
    ExecutableProduct("overRhoPimpleDyMFoam", :overRhoPimpleDyMFoam),
    ExecutableProduct("foamToStarMesh", :foamToStarMesh),
    ExecutableProduct("chemkinToFoam", :chemkinToFoam),
    ExecutableProduct("magneticFoam", :magneticFoam),
    ExecutableProduct("potentialFreeSurfaceDyMFoam", :potentialFreeSurfaceDyMFoam),
    ExecutableProduct("foamHelp", :foamHelp),
    ExecutableProduct("PDRMesh", :PDRMesh),
    ExecutableProduct("buoyantBoussinesqPimpleFoam", :buoyantBoussinesqPimpleFoam),
    ExecutableProduct("foamToVTK", :foamToVTK),
    ExecutableProduct("smoothSurfaceData", :smoothSurfaceData),
    ExecutableProduct("surfaceInertia", :surfaceInertia),
    ExecutableProduct("foamToSurface", :foamToSurface),
    ExecutableProduct("adjointShapeOptimizationFoam", :adjointShapeOptimizationFoam),
    ExecutableProduct("surfaceOrient", :surfaceOrient),
    ExecutableProduct("overPotentialFoam", :overPotentialFoam),
    ExecutableProduct("polyDualMesh", :polyDualMesh),
    ExecutableProduct("adiabaticFlameT", :adiabaticFlameT),
    ExecutableProduct("ansysToFoam", :ansysToFoam),
    ExecutableProduct("compressibleInterDyMFoam", :compressibleInterDyMFoam),
    ExecutableProduct("zipUpMesh", :zipUpMesh),
    ExecutableProduct("cfx4ToFoam", :cfx4ToFoam),
    ExecutableProduct("sprayFoam", :sprayFoam),
    ExecutableProduct("overPimpleDyMFoam", :overPimpleDyMFoam),
    ExecutableProduct("financialFoam", :financialFoam),
    ExecutableProduct("dsmcFoam", :dsmcFoam),
    ExecutableProduct("cavitatingDyMFoam", :cavitatingDyMFoam),
    ExecutableProduct("sphereSurfactantFoam", :sphereSurfactantFoam),
    ExecutableProduct("surfaceFeatureConvert", :surfaceFeatureConvert),
    ExecutableProduct("postChannel", :postChannel),
    ExecutableProduct("setSet", :setSet),
    ExecutableProduct("surfaceCoarsen", :surfaceCoarsen),
    ExecutableProduct("icoUncoupledKinematicParcelDyMFoam", :icoUncoupledKinematicParcelDyMFoam),
    ExecutableProduct("interCondensatingEvaporatingFoam", :interCondensatingEvaporatingFoam),
    ExecutableProduct("surfaceBooleanFeatures", :surfaceBooleanFeatures),
    ExecutableProduct("adjointOptimisationFoam", :adjointOptimisationFoam),
    ExecutableProduct("reactingHeterogenousParcelFoam", :reactingHeterogenousParcelFoam),
    ExecutableProduct("foamToEnsight", :foamToEnsight),
    ExecutableProduct("simpleFoam", :simpleFoam),
    ExecutableProduct("splitMesh", :splitMesh),
    ExecutableProduct("foamDataToFluent", :foamDataToFluent),
    ExecutableProduct("createBoxTurb", :createBoxTurb),
    ExecutableProduct("surfaceSplitByTopology", :surfaceSplitByTopology),
    ExecutableProduct("overInterDyMFoam", :overInterDyMFoam),
    ExecutableProduct("compressibleMultiphaseInterFoam", :compressibleMultiphaseInterFoam),
    ExecutableProduct("acousticFoam", :acousticFoam),
    ExecutableProduct("gambitToFoam", :gambitToFoam),
    ExecutableProduct("mshToFoam", :mshToFoam),
    ExecutableProduct("interPhaseChangeFoam", :interPhaseChangeFoam),
    ExecutableProduct("cavitatingFoam", :cavitatingFoam),
    ExecutableProduct("PDRFoam", :PDRFoam),
    ExecutableProduct("surfaceLambdaMuSmooth", :surfaceLambdaMuSmooth),
    ExecutableProduct("steadyParticleTracks", :steadyParticleTracks),
    ExecutableProduct("rhoPorousSimpleFoam", :rhoPorousSimpleFoam),
    ExecutableProduct("profilingSummary", :profilingSummary),
    ExecutableProduct("pdfPlot", :pdfPlot),
    ExecutableProduct("rotateMesh", :rotateMesh),
    ExecutableProduct("tetgenToFoam", :tetgenToFoam),
    ExecutableProduct("engineCompRatio", :engineCompRatio),
    ExecutableProduct("foamToFireMesh", :foamToFireMesh),
    ExecutableProduct("objToVTK", :objToVTK),
    ExecutableProduct("MPPICFoam", :MPPICFoam),
    ExecutableProduct("XiEngineFoam", :XiEngineFoam),
    ExecutableProduct("insideCells", :insideCells),
    ExecutableProduct("createExternalCoupledPatchGeometry", :createExternalCoupledPatchGeometry),
    ExecutableProduct("rhoCentralFoam", :rhoCentralFoam),
    ExecutableProduct("combinePatchFaces", :combinePatchFaces),
    ExecutableProduct("SRFSimpleFoam", :SRFSimpleFoam),
    ExecutableProduct("equilibriumFlameT", :equilibriumFlameT),
    ExecutableProduct("reconstructParMesh", :reconstructParMesh),
    ExecutableProduct("foamListRegions", :foamListRegions),
    ExecutableProduct("makeFaMesh", :makeFaMesh),
    ExecutableProduct("chtMultiRegionTwoPhaseEulerFoam", :chtMultiRegionTwoPhaseEulerFoam),
    ExecutableProduct("sprayDyMFoam", :sprayDyMFoam),
    ExecutableProduct("mergeOrSplitBaffles", :mergeOrSplitBaffles),
    ExecutableProduct("interMixingFoam", :interMixingFoam),
    ExecutableProduct("plot3dToFoam", :plot3dToFoam),
    ExecutableProduct("DPMFoam", :DPMFoam),
    ExecutableProduct("SRFPimpleFoam", :SRFPimpleFoam),
    ExecutableProduct("buoyantPimpleFoam", :buoyantPimpleFoam),
    ExecutableProduct("mdInitialise", :mdInitialise),
    ExecutableProduct("viewFactorsGen", :viewFactorsGen),
    ExecutableProduct("overInterPhaseChangeDyMFoam", :overInterPhaseChangeDyMFoam),
    ExecutableProduct("twoLiquidMixingFoam", :twoLiquidMixingFoam),
    ExecutableProduct("simpleSprayFoam", :simpleSprayFoam),
    ExecutableProduct("applyBoundaryLayer", :applyBoundaryLayer),
    ExecutableProduct("foamDictionary", :foamDictionary),
    ExecutableProduct("scalarTransportFoam", :scalarTransportFoam),
    ExecutableProduct("splitCells", :splitCells),
    ExecutableProduct("PDRsetFields", :PDRsetFields),
    ExecutableProduct("setAlphaField", :setAlphaField),
    ExecutableProduct("surfaceConvert", :surfaceConvert),
    ExecutableProduct("interPhaseChangeDyMFoam", :interPhaseChangeDyMFoam),
    ExecutableProduct("potentialFoam", :potentialFoam),
    ExecutableProduct("surfaceToPatch", :surfaceToPatch),
    ExecutableProduct("surfacePatch", :surfacePatch),
    ExecutableProduct("foamRestoreFields", :foamRestoreFields),
    ExecutableProduct("sonicDyMFoam", :sonicDyMFoam),
    ExecutableProduct("surfaceMeshExport", :surfaceMeshExport),
    ExecutableProduct("mapFields", :mapFields),
    ExecutableProduct("uncoupledKinematicParcelFoam", :uncoupledKinematicParcelFoam),
    ExecutableProduct("boundaryFoam", :boundaryFoam),
    ExecutableProduct("PDRblockMesh", :PDRblockMesh),
    ExecutableProduct("chtMultiRegionFoam", :chtMultiRegionFoam),
    ExecutableProduct("foamHasLibrary", :foamHasLibrary),
    ExecutableProduct("setExprBoundaryFields", :setExprBoundaryFields),
    ExecutableProduct("singleCellMesh", :singleCellMesh),
    ExecutableProduct("icoFoam", :icoFoam),
    ExecutableProduct("mapFieldsPar", :mapFieldsPar),
    ExecutableProduct("XiFoam", :XiFoam),
    ExecutableProduct("refineMesh", :refineMesh),
    ExecutableProduct("mdFoam", :mdFoam),
    ExecutableProduct("changeDictionary", :changeDictionary),
    ExecutableProduct("simpleCoalParcelFoam", :simpleCoalParcelFoam),
    ExecutableProduct("surfaceInflate", :surfaceInflate),
    ExecutableProduct("shallowWaterFoam", :shallowWaterFoam),
    ExecutableProduct("vtkUnstructuredToFoam", :vtkUnstructuredToFoam),
    ExecutableProduct("sonicFoam", :sonicFoam),
    ExecutableProduct("particleTracks", :particleTracks),
    ExecutableProduct("surfaceMeshInfo", :surfaceMeshInfo),
    ExecutableProduct("createROMfields", :createROMfields),
    ExecutableProduct("electrostaticFoam", :electrostaticFoam),
    ExecutableProduct("setExprFields", :setExprFields),
    ExecutableProduct("foamToGMV", :foamToGMV),
    ExecutableProduct("dsmcInitialise", :dsmcInitialise),
    ExecutableProduct("snappyRefineMesh", :snappyRefineMesh),
    ExecutableProduct("surfaceRefineRedGreen", :surfaceRefineRedGreen),
    ExecutableProduct("overSimpleFoam", :overSimpleFoam),
    ExecutableProduct("mdEquilibrationFoam", :mdEquilibrationFoam),
    ExecutableProduct("decomposePar", :decomposePar),
    ExecutableProduct("simpleReactingParcelFoam", :simpleReactingParcelFoam),
    ExecutableProduct("refineHexMesh", :refineHexMesh),
    ExecutableProduct("transformPoints", :transformPoints),
    ExecutableProduct("selectCells", :selectCells),
    ExecutableProduct("gmshToFoam", :gmshToFoam),
    ExecutableProduct("surfaceMeshConvert", :surfaceMeshConvert),
    ExecutableProduct("snappyHexMesh", :snappyHexMesh),
    ExecutableProduct("fireToFoam", :fireToFoam),
    ExecutableProduct("checkMesh", :checkMesh),
    ExecutableProduct("createBaffles", :createBaffles),
    ExecutableProduct("surfaceRedistributePar", :surfaceRedistributePar),
    ExecutableProduct("setTurbulenceFields", :setTurbulenceFields),
    ExecutableProduct("reactingMultiphaseEulerFoam", :reactingMultiphaseEulerFoam),
    ExecutableProduct("collapseEdges", :collapseEdges),
    ExecutableProduct("foamMeshToFluent", :foamMeshToFluent),
    ExecutableProduct("moveEngineMesh", :moveEngineMesh),
    ExecutableProduct("orientFaceZone", :orientFaceZone),
    ExecutableProduct("smapToFoam", :smapToFoam),
    ExecutableProduct("surfaceSubset", :surfaceSubset),
    ExecutableProduct("reactingTwoPhaseEulerFoam", :reactingTwoPhaseEulerFoam),
    ExecutableProduct("rhoPimpleAdiabaticFoam", :rhoPimpleAdiabaticFoam),
    ExecutableProduct("topoSet", :topoSet),
    ExecutableProduct("postProcess", :postProcess),
    ExecutableProduct("computeSensitivities", :computeSensitivities),
    ExecutableProduct("interFoam", :interFoam),
    ExecutableProduct("foamToTetDualMesh", :foamToTetDualMesh),
    ExecutableProduct("surfaceClean", :surfaceClean),
    ExecutableProduct("icoUncoupledKinematicParcelFoam", :icoUncoupledKinematicParcelFoam),
    ExecutableProduct("mirrorMesh", :mirrorMesh),
    ExecutableProduct("uncoupledKinematicParcelDyMFoam", :uncoupledKinematicParcelDyMFoam),
    ExecutableProduct("extrude2DMesh", :extrude2DMesh),
    ExecutableProduct("attachMesh", :attachMesh),
    ExecutableProduct("surfaceFeatureExtract", :surfaceFeatureExtract),
    ExecutableProduct("chtMultiRegionSimpleFoam", :chtMultiRegionSimpleFoam),
    ExecutableProduct("potentialFreeSurfaceFoam", :potentialFreeSurfaceFoam),
    ExecutableProduct("moveDynamicMesh", :moveDynamicMesh),
    ExecutableProduct("setFields", :setFields),
    ExecutableProduct("subsetMesh", :subsetMesh),
    ExecutableProduct("createPatch", :createPatch),
    ExecutableProduct("compressibleInterIsoFoam", :compressibleInterIsoFoam),
    ExecutableProduct("refineWallLayer", :refineWallLayer),
    ExecutableProduct("MPPICDyMFoam", :MPPICDyMFoam),
    ExecutableProduct("renumberMesh", :renumberMesh),
    ExecutableProduct("foamUpgradeCyclics", :foamUpgradeCyclics),
    ExecutableProduct("overRhoSimpleFoam", :overRhoSimpleFoam),
    ExecutableProduct("pisoFoam", :pisoFoam),
    ExecutableProduct("rhoPimpleFoam", :rhoPimpleFoam),
    ExecutableProduct("engineFoam", :engineFoam),
    FileProduct("share/openfoam/etc", :openfoam_etc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
    Dependency(PackageSpec(name="SCOTCH_jll", build_version=VersionNumber(SCOTCH_VERSION)))
    Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"))
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version = v"12")
