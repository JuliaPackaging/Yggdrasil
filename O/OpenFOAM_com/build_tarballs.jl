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
git submodule update --init modules/cfmesh modules/avalanche

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
cp -r bin/ "${prefix}/share/openfoam/."
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
    LibraryProduct("libengine", :libengine; dont_dlopen=true),
    LibraryProduct("libdistributionModels", :libdistributionModels; dont_dlopen=true),
    LibraryProduct("libtwoPhaseReactingTurbulenceModels", :libtwoPhaseReactingTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libfiniteArea", :libfiniteArea; dont_dlopen=true),
    LibraryProduct("libmultiphaseSystem", :libmultiphaseSystem; dont_dlopen=true),
    LibraryProduct("libcompressibleTurbulenceModels", :libcompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libsaturationModel", :libsaturationModel; dont_dlopen=true),
    LibraryProduct("libsurfMesh", :libsurfMesh; dont_dlopen=true),
    LibraryProduct("liblagrangianIntermediate", :liblagrangianIntermediate; dont_dlopen=true),
    LibraryProduct("libthermoTools", :libthermoTools; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmDerivedFvPatchFields", :libsurfaceFilmDerivedFvPatchFields; dont_dlopen=true),
    LibraryProduct("libreactingMultiphaseSystem", :libreactingMultiphaseSystem; dont_dlopen=true),
    LibraryProduct("libmeshTools", :libmeshTools; dont_dlopen=true),
    LibraryProduct("libptscotchDecomp", :libptscotchDecomp; dont_dlopen=true),
    LibraryProduct("libdecompositionMethods", :libdecompositionMethods; dont_dlopen=true),
    LibraryProduct("libconversion", :libconversion; dont_dlopen=true),
    LibraryProduct("libincompressibleMultiphaseSystems", :libincompressibleMultiphaseSystems; dont_dlopen=true),
    LibraryProduct("libfaDecompose", :libfaDecompose; dont_dlopen=true),
    LibraryProduct("libincompressibleTransportModels", :libincompressibleTransportModels; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixture", :libtwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libsolverFunctionObjects", :libsolverFunctionObjects; dont_dlopen=true),
    LibraryProduct("libinterfaceProperties", :libinterfaceProperties; dont_dlopen=true),
    LibraryProduct("libfvMotionSolvers", :libfvMotionSolvers; dont_dlopen=true),
    LibraryProduct("libtabulatedWallFunctions", :libtabulatedWallFunctions; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixtureThermo", :libtwoPhaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libregionFaModels", :libregionFaModels; dont_dlopen=true),
    LibraryProduct("libsampling", :libsampling; dont_dlopen=true),
    LibraryProduct("libalphaFieldFunctions", :libalphaFieldFunctions; dont_dlopen=true),
    LibraryProduct("liblagrangianSpray", :liblagrangianSpray; dont_dlopen=true),
    LibraryProduct("liblagrangian", :liblagrangian; dont_dlopen=true),
    LibraryProduct("libinitialisationFunctionObjects", :libinitialisationFunctionObjects; dont_dlopen=true),
    LibraryProduct("libDSMC", :libDSMC; dont_dlopen=true),
    LibraryProduct("libfileFormats", :libfileFormats; dont_dlopen=true),
    LibraryProduct("libimmiscibleIncompressibleTwoPhaseMixture", :libimmiscibleIncompressibleTwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libMGridGen", :libMGridGen; dont_dlopen=true),
    LibraryProduct("libinterfaceTrackingFvMesh", :libinterfaceTrackingFvMesh; dont_dlopen=true),
    LibraryProduct("libmolecularMeasurements", :libmolecularMeasurements; dont_dlopen=true),
    LibraryProduct("librenumberMethods", :librenumberMethods; dont_dlopen=true),
    LibraryProduct("libhelpTypes", :libhelpTypes; dont_dlopen=true),
    LibraryProduct("libtwoPhaseProperties", :libtwoPhaseProperties; dont_dlopen=true),
    LibraryProduct("libchemistryModel", :libchemistryModel; dont_dlopen=true),
    LibraryProduct("libfvOptions", :libfvOptions; dont_dlopen=true),
    LibraryProduct("libdynamicMesh", :libdynamicMesh; dont_dlopen=true),
    LibraryProduct("libkahipDecomp", :libkahipDecomp; dont_dlopen=true),
    LibraryProduct("libspecie", :libspecie; dont_dlopen=true),
    LibraryProduct("libturbulenceModels", :libturbulenceModels; dont_dlopen=true),
    LibraryProduct("libdriftFluxRelativeVelocityModels", :libdriftFluxRelativeVelocityModels; dont_dlopen=true),
    LibraryProduct("libpotential", :libpotential; dont_dlopen=true),
    LibraryProduct("libphaseFunctionObjects", :libphaseFunctionObjects; dont_dlopen=true),
    LibraryProduct("liblaminarFlameSpeedModels", :liblaminarFlameSpeedModels; dont_dlopen=true),
    LibraryProduct("libpairPatchAgglomeration", :libpairPatchAgglomeration; dont_dlopen=true),
    LibraryProduct("libgenericPatchFields", :libgenericPatchFields; dont_dlopen=true),
    LibraryProduct("libdecompose", :libdecompose; dont_dlopen=true),
    LibraryProduct("libreactionThermophysicalModels", :libreactionThermophysicalModels; dont_dlopen=true),
    LibraryProduct("libSLGThermo", :libSLGThermo; dont_dlopen=true),
    LibraryProduct("libfiniteVolume", :libfiniteVolume; dont_dlopen=true),
    LibraryProduct("libturbulenceModelSchemes", :libturbulenceModelSchemes; dont_dlopen=true),
    LibraryProduct("libfaOptions", :libfaOptions; dont_dlopen=true),
    LibraryProduct("libextrudeModel", :libextrudeModel; dont_dlopen=true),
    LibraryProduct("libregionModels", :libregionModels; dont_dlopen=true),
    LibraryProduct("libsolidSpecie", :libsolidSpecie; dont_dlopen=true),
    LibraryProduct("liblagrangianTurbulence", :liblagrangianTurbulence; dont_dlopen=true),
    LibraryProduct("libincompressibleInterPhaseTransportModels", :libincompressibleInterPhaseTransportModels; dont_dlopen=true),
    LibraryProduct("librigidBodyDynamics", :librigidBodyDynamics; dont_dlopen=true),
    LibraryProduct("libDPMTurbulenceModels", :libDPMTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libPstream", :libPstream; dont_dlopen=true),
    LibraryProduct("libsolidChemistryModel", :libsolidChemistryModel; dont_dlopen=true),
    LibraryProduct("libcompressibleMultiPhaseTurbulenceModels", :libcompressibleMultiPhaseTurbulenceModels; dont_dlopen=true),
    LibraryProduct("liblaserDTRM", :liblaserDTRM; dont_dlopen=true),
    LibraryProduct("libVoFphaseCompressibleTurbulenceModels", :libVoFphaseCompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("liblumpedPointMotion", :liblumpedPointMotion; dont_dlopen=true),
    LibraryProduct("libmolecule", :libmolecule; dont_dlopen=true),
    LibraryProduct("libOpenFOAM", :libOpenFOAM; dont_dlopen=true),
    LibraryProduct("libcompressibleTransportModels", :libcompressibleTransportModels; dont_dlopen=true),
    LibraryProduct("librigidBodyMeshMotion", :librigidBodyMeshMotion; dont_dlopen=true),
    LibraryProduct("libfaReconstruct", :libfaReconstruct; dont_dlopen=true),
    LibraryProduct("libthermophysicalProperties", :libthermophysicalProperties; dont_dlopen=true),
    LibraryProduct("libwaveModels", :libwaveModels; dont_dlopen=true),
    LibraryProduct("libsolidParticle", :libsolidParticle; dont_dlopen=true),
    LibraryProduct("libradiationModels", :libradiationModels; dont_dlopen=true),
    LibraryProduct("libcompressibleTwoPhaseMixtureTurbulenceModels", :libcompressibleTwoPhaseMixtureTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libpdrFields", :libpdrFields; dont_dlopen=true),
    LibraryProduct("libsolidThermo", :libsolidThermo; dont_dlopen=true),
    LibraryProduct("libfieldFunctionObjects", :libfieldFunctionObjects; dont_dlopen=true),
    LibraryProduct("libdynamicFvMesh", :libdynamicFvMesh; dont_dlopen=true),
    LibraryProduct("libreconstruct", :libreconstruct; dont_dlopen=true),
    LibraryProduct("libdistributed", :libdistributed; dont_dlopen=true),
    LibraryProduct("libreactingTwoPhaseSystem", :libreactingTwoPhaseSystem; dont_dlopen=true),
    LibraryProduct("libthermalBaffleModels", :libthermalBaffleModels; dont_dlopen=true),
    LibraryProduct("libscotchDecomp", :libscotchDecomp; dont_dlopen=true),
    LibraryProduct("libphaseChangeTwoPhaseMixtures", :libphaseChangeTwoPhaseMixtures; dont_dlopen=true),
    LibraryProduct("libmultiphaseMixtureThermo", :libmultiphaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libVoFphaseTurbulentTransportModels", :libVoFphaseTurbulentTransportModels; dont_dlopen=true),
    LibraryProduct("libcoalCombustion", :libcoalCombustion; dont_dlopen=true),
    LibraryProduct("liblagrangianFunctionObjects", :liblagrangianFunctionObjects; dont_dlopen=true),
    LibraryProduct("libforces", :libforces; dont_dlopen=true),
    LibraryProduct("libcombustionModels", :libcombustionModels; dont_dlopen=true),
    LibraryProduct("libphaseTemperatureChangeTwoPhaseMixtures", :libphaseTemperatureChangeTwoPhaseMixtures; dont_dlopen=true),
    LibraryProduct("libextrude2DMesh", :libextrude2DMesh; dont_dlopen=true),
    LibraryProduct("libregionCoupling", :libregionCoupling; dont_dlopen=true),
    LibraryProduct("libODE", :libODE; dont_dlopen=true),
    LibraryProduct("libcompressibleTwoPhaseSystem", :libcompressibleTwoPhaseSystem; dont_dlopen=true),
    LibraryProduct("libgeometricVoF", :libgeometricVoF; dont_dlopen=true),
    LibraryProduct("libtopoChangerFvMesh", :libtopoChangerFvMesh; dont_dlopen=true),
    LibraryProduct("libdriftFluxTransportModels", :libdriftFluxTransportModels; dont_dlopen=true),
    LibraryProduct("libadjointOptimisation", :libadjointOptimisation; dont_dlopen=true),
    LibraryProduct("libutilityFunctionObjects", :libutilityFunctionObjects; dont_dlopen=true),
    LibraryProduct("libtwoPhaseSurfaceTension", :libtwoPhaseSurfaceTension; dont_dlopen=true),
    LibraryProduct("libatmosphericModels", :libatmosphericModels; dont_dlopen=true),
    LibraryProduct("libsurfaceFeatureExtract", :libsurfaceFeatureExtract; dont_dlopen=true),
    LibraryProduct("libbarotropicCompressibilityModel", :libbarotropicCompressibilityModel; dont_dlopen=true),
    LibraryProduct("libsnappyHexMesh", :libsnappyHexMesh; dont_dlopen=true),
    LibraryProduct("librhoCentralFoam", :librhoCentralFoam; dont_dlopen=true),
    LibraryProduct("libphaseCompressibleTurbulenceModels", :libphaseCompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libmultiphaseInterFoam", :libmultiphaseInterFoam; dont_dlopen=true),
    LibraryProduct("libblockMesh", :libblockMesh; dont_dlopen=true),
    LibraryProduct("liboverset", :liboverset; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmModels", :libsurfaceFilmModels; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyMotion", :libsixDoFRigidBodyMotion; dont_dlopen=true),
    LibraryProduct("libmetisDecomp", :libmetisDecomp; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyState", :libsixDoFRigidBodyState; dont_dlopen=true),
    LibraryProduct("libpyrolysisModels", :libpyrolysisModels; dont_dlopen=true),
    LibraryProduct("libincompressibleTurbulenceModels", :libincompressibleTurbulenceModels; dont_dlopen=true),
    LibraryProduct("libfluidThermophysicalModels", :libfluidThermophysicalModels; dont_dlopen=true),
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
    FileProduct("share/openfoam/etc", :openfoam_etc), 
    FileProduct("share/openfoam/bin", :openfoam_bin)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"))
    Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"))
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    RuntimeDependency(PackageSpec(name = "M4_jll", uuid = "9051c120-a745-5e86-aaa7-8cbc404dba28"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
    preferred_gcc_version = v"12")
