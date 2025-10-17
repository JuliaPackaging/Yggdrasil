# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenFOAM"
version = v"8.0.1"
openfoam_version = v"8.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/OpenFOAM/OpenFOAM-8/archive/version-8.tar.gz",
                  "94ba11cbaaa12fbb5b356e01758df403ac8832d69da309a5d79f76f42eb008fc"),
    DirectorySource("./bundled"),
]

# In order to set up OpenFOAM, we need to know the version of some of the
# dependencies.
const SCOTCH_VERSION = "6.1.0"
const SCOTCH_COMPAT_VERSION = "6.1.3"

# Bash recipe for building across all platforms
script = "SCOTCH_VERSION=$(SCOTCH_VERSION)\n" * raw"""
cd ${WORKSPACE}/srcdir/OpenFOAM*
atomic_patch -p1 ../patches/etc-bashrc.patch

# Set rpath-link in all C/C++ compilers
LDFLAGS=""
for dir in "" "/dummy" "/mpi-system"; do
    LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"
done
sed -i "s?-m64?-m64 ${LDFLAGS}?g" wmake/rules/*/c*

# Set version of Scotch
echo "export SCOTCH_VERSION=${SCOTCH_VERSION}" > etc/config.sh/scotch
echo "export SCOTCH_ARCH_PATH=${prefix}"      >> etc/config.sh/scotch

# Set up to use our MPI
sed -i 's/WM_MPLIB=SYSTEMOPENMPI/WM_MPLIB=SYSTEMMPI/g' etc/bashrc
export MPI_ROOT="${prefix}"
export MPI_ARCH_FLAGS=""
export MPI_ARCH_INC="-I${includedir}"
if grep -q MPICH_NAME $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi"
elif grep -q MPItrampoline $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpitrampoline"
elif grep -q OMPI_MAJOR_VERSION $prefix/include/mpi.h; then
    export MPI_ARCH_LIBS="-L${libdir} -lmpi"
fi

# Set up the environment.  Note, this script may internally have some failing command, which
# would spring our traps, so we have to allow failures, sigh
source etc/bashrc || true

# Build!
./Allwmake -j${nproc}

# Highly advanced installation process (inspired by Debian:
# https://salsa.debian.org/science-team/openfoam/-/tree/master/debian)
mkdir -p "${libdir}" "${bindir}" "${prefix}/share/openfoam"
cp platforms/linux64GccDPInt32Opt/lib/{,dummy/,mpi-system/}*.${dlext}* "${libdir}/."
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
    Platform("x86_64", "linux"; libc="glibc"),
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
    LibraryProduct("libatmosphericModels", :libatmosphericModels; dont_dlopen=true),
    LibraryProduct("libbarotropicCompressibilityModel", :libbarotropicCompressibilityModel; dont_dlopen=true),
    LibraryProduct("libblockMesh", :libblockMesh; dont_dlopen=true),
    LibraryProduct("libchemistryModel", :libchemistryModel; dont_dlopen=true),
    LibraryProduct("libcoalCombustion", :libcoalCombustion; dont_dlopen=true),
    LibraryProduct("libcombustionModels", :libcombustionModels; dont_dlopen=true),
    LibraryProduct("libconversion", :libconversion; dont_dlopen=true),
    LibraryProduct("libdecompose", :libdecompose; dont_dlopen=true),
    LibraryProduct("libdecompositionMethods", :libdecompositionMethods; dont_dlopen=true),
    LibraryProduct("libdistributed", :libdistributed; dont_dlopen=true),
    LibraryProduct("libdistributionModels", :libdistributionModels; dont_dlopen=true),
    LibraryProduct("libDPMMomentumTransportModels", :libDPMMomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libdriftFluxRelativeVelocityModels", :libdriftFluxRelativeVelocityModels; dont_dlopen=true),
    LibraryProduct("libdriftFluxTransportModels", :libdriftFluxTransportModels; dont_dlopen=true),
    LibraryProduct("libDSMC", :libDSMC; dont_dlopen=true),
    LibraryProduct("libdynamicFvMesh", :libdynamicFvMesh; dont_dlopen=true),
    LibraryProduct("libdynamicMesh", :libdynamicMesh; dont_dlopen=true),
    LibraryProduct("libengine", :libengine; dont_dlopen=true),
    LibraryProduct("libeulerianInterfacialCompositionModels", :libeulerianInterfacialCompositionModels; dont_dlopen=true),
    LibraryProduct("libeulerianInterfacialModels", :libeulerianInterfacialModels; dont_dlopen=true),
    LibraryProduct("libextrude2DMesh", :libextrude2DMesh; dont_dlopen=true),
    LibraryProduct("libextrudeModel", :libextrudeModel; dont_dlopen=true),
    LibraryProduct("libfieldFunctionObjects", :libfieldFunctionObjects; dont_dlopen=true),
    LibraryProduct("libfileFormats", :libfileFormats; dont_dlopen=true),
    LibraryProduct("libfiniteVolume", :libfiniteVolume; dont_dlopen=true),
    LibraryProduct("libfluidThermoMomentumTransportModels", :libfluidThermoMomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libfluidThermophysicalModels", :libfluidThermophysicalModels; dont_dlopen=true),
    LibraryProduct("libfoamToVTK", :libfoamToVTK; dont_dlopen=true),
    LibraryProduct("libforces", :libforces; dont_dlopen=true),
    LibraryProduct("libfvMotionSolvers", :libfvMotionSolvers; dont_dlopen=true),
    LibraryProduct("libfvOptions", :libfvOptions; dont_dlopen=true),
    LibraryProduct("libgenericPatchFields", :libgenericPatchFields; dont_dlopen=true),
    LibraryProduct("libimmiscibleIncompressibleTwoPhaseMixture", :libimmiscibleIncompressibleTwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libincompressibleMomentumTransportModels", :libincompressibleMomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libincompressibleTransportModels", :libincompressibleTransportModels; dont_dlopen=true),
    LibraryProduct("libincompressibleTwoPhaseMixture", :libincompressibleTwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libinterfaceProperties", :libinterfaceProperties; dont_dlopen=true),
    LibraryProduct("liblagrangianFunctionObjects", :liblagrangianFunctionObjects; dont_dlopen=true),
    LibraryProduct("liblagrangianIntermediate", :liblagrangianIntermediate; dont_dlopen=true),
    LibraryProduct("liblagrangian", :liblagrangian; dont_dlopen=true),
    LibraryProduct("liblagrangianSpray", :liblagrangianSpray; dont_dlopen=true),
    LibraryProduct("liblagrangianTurbulence", :liblagrangianTurbulence; dont_dlopen=true),
    LibraryProduct("liblaminarFlameSpeedModels", :liblaminarFlameSpeedModels; dont_dlopen=true),
    LibraryProduct("libmeshTools", :libmeshTools; dont_dlopen=true),
    LibraryProduct("libmetisDecomp", :libmetisDecomp; dont_dlopen=true),
    LibraryProduct("libMGridGen", :libMGridGen; dont_dlopen=true),
    LibraryProduct("libmolecularMeasurements", :libmolecularMeasurements; dont_dlopen=true),
    LibraryProduct("libmolecule", :libmolecule; dont_dlopen=true),
    LibraryProduct("libmomentumTransportModels", :libmomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libmultiphaseEulerFoamFunctionObjects", :libmultiphaseEulerFoamFunctionObjects; dont_dlopen=true),
    LibraryProduct("libmultiphaseInterFoam", :libmultiphaseInterFoam; dont_dlopen=true),
    LibraryProduct("libmultiphaseMixtureThermo", :libmultiphaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libmultiphaseMomentumTransportModels", :libmultiphaseMomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libmultiphaseSystems", :libmultiphaseSystems; dont_dlopen=true),
    LibraryProduct("libmultiphaseThermophysicalTransportModels", :libmultiphaseThermophysicalTransportModels; dont_dlopen=true),
    LibraryProduct("libODE", :libODE; dont_dlopen=true),
    LibraryProduct("libOpenFOAM", :libOpenFOAM; dont_dlopen=true),
    LibraryProduct("libpairPatchAgglomeration", :libpairPatchAgglomeration; dont_dlopen=true),
    LibraryProduct("libphaseChangeTwoPhaseMixtures", :libphaseChangeTwoPhaseMixtures; dont_dlopen=true),
    LibraryProduct("libphaseSystem", :libphaseSystem; dont_dlopen=true),
    LibraryProduct("libpotential", :libpotential; dont_dlopen=true),
    LibraryProduct("libpsiReactionThermophysicalTransportModels", :libpsiReactionThermophysicalTransportModels; dont_dlopen=true),
    LibraryProduct("libPstream", :libPstream; dont_dlopen=true),
    LibraryProduct("libptscotchDecomp", :libptscotchDecomp; dont_dlopen=true),
    LibraryProduct("libradiationModels", :libradiationModels; dont_dlopen=true),
    LibraryProduct("librandomProcesses", :librandomProcesses; dont_dlopen=true),
    LibraryProduct("libreactionThermophysicalModels", :libreactionThermophysicalModels; dont_dlopen=true),
    LibraryProduct("libreconstruct", :libreconstruct; dont_dlopen=true),
    LibraryProduct("libregionModels", :libregionModels; dont_dlopen=true),
    LibraryProduct("librenumberMethods", :librenumberMethods; dont_dlopen=true),
    LibraryProduct("librhoCentralFoam", :librhoCentralFoam; dont_dlopen=true),
    LibraryProduct("librhoReactionThermophysicalTransportModels", :librhoReactionThermophysicalTransportModels; dont_dlopen=true),
    LibraryProduct("librigidBodyDynamics", :librigidBodyDynamics; dont_dlopen=true),
    LibraryProduct("librigidBodyMeshMotion", :librigidBodyMeshMotion; dont_dlopen=true),
    LibraryProduct("librigidBodyState", :librigidBodyState; dont_dlopen=true),
    LibraryProduct("libsampling", :libsampling; dont_dlopen=true),
    LibraryProduct("libscotchDecomp", :libscotchDecomp; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyMotion", :libsixDoFRigidBodyMotion; dont_dlopen=true),
    LibraryProduct("libsixDoFRigidBodyState", :libsixDoFRigidBodyState; dont_dlopen=true),
    LibraryProduct("libSLGThermo", :libSLGThermo; dont_dlopen=true),
    LibraryProduct("libsnappyHexMesh", :libsnappyHexMesh; dont_dlopen=true),
    LibraryProduct("libsolidDisplacementThermo", :libsolidDisplacementThermo; dont_dlopen=true),
    LibraryProduct("libsolidParticle", :libsolidParticle; dont_dlopen=true),
    LibraryProduct("libsolidThermo", :libsolidThermo; dont_dlopen=true),
    LibraryProduct("libsolverFunctionObjects", :libsolverFunctionObjects; dont_dlopen=true),
    LibraryProduct("libspecie", :libspecie; dont_dlopen=true),
    LibraryProduct("libspecieTransfer", :libspecieTransfer; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmDerivedFvPatchFields", :libsurfaceFilmDerivedFvPatchFields; dont_dlopen=true),
    LibraryProduct("libsurfaceFilmModels", :libsurfaceFilmModels; dont_dlopen=true),
    LibraryProduct("libsurfMesh", :libsurfMesh; dont_dlopen=true),
    LibraryProduct("libtabulatedWallFunctions", :libtabulatedWallFunctions; dont_dlopen=true),
    LibraryProduct("libthermalBaffleModels", :libthermalBaffleModels; dont_dlopen=true),
    LibraryProduct("libthermophysicalProperties", :libthermophysicalProperties; dont_dlopen=true),
    LibraryProduct("libthermophysicalTransportModels", :libthermophysicalTransportModels; dont_dlopen=true),
    LibraryProduct("libtopoChangerFvMesh", :libtopoChangerFvMesh; dont_dlopen=true),
    LibraryProduct("libtriSurface", :libtriSurface; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixture", :libtwoPhaseMixture; dont_dlopen=true),
    LibraryProduct("libtwoPhaseMixtureThermo", :libtwoPhaseMixtureThermo; dont_dlopen=true),
    LibraryProduct("libtwoPhaseProperties", :libtwoPhaseProperties; dont_dlopen=true),
    LibraryProduct("libtwoPhaseSurfaceTension", :libtwoPhaseSurfaceTension; dont_dlopen=true),
    LibraryProduct("libuserd-foam", :libuserd_foam; dont_dlopen=true),
    LibraryProduct("libutilityFunctionObjects", :libutilityFunctionObjects; dont_dlopen=true),
    LibraryProduct("libVoFphaseCompressibleMomentumTransportModels", :libVoFphaseCompressibleMomentumTransportModels; dont_dlopen=true),
    LibraryProduct("libwaves", :libwaves; dont_dlopen=true),
    ExecutableProduct("adiabaticFlameT", :adiabaticFlameT),
    ExecutableProduct("adjointShapeOptimizationFoam", :adjointShapeOptimizationFoam),
    ExecutableProduct("ansysToFoam", :ansysToFoam),
    ExecutableProduct("applyBoundaryLayer", :applyBoundaryLayer),
    ExecutableProduct("attachMesh", :attachMesh),
    ExecutableProduct("autoPatch", :autoPatch),
    ExecutableProduct("autoRefineMesh", :autoRefineMesh),
    ExecutableProduct("blockMesh", :blockMesh),
    ExecutableProduct("boundaryFoam", :boundaryFoam),
    ExecutableProduct("boxTurb", :boxTurb),
    ExecutableProduct("buoyantPimpleFoam", :buoyantPimpleFoam),
    ExecutableProduct("buoyantSimpleFoam", :buoyantSimpleFoam),
    ExecutableProduct("cavitatingFoam", :cavitatingFoam),
    ExecutableProduct("cfx4ToFoam", :cfx4ToFoam),
    ExecutableProduct("changeDictionary", :changeDictionary),
    ExecutableProduct("checkMesh", :checkMesh),
    ExecutableProduct("chemFoam", :chemFoam),
    ExecutableProduct("chemkinToFoam", :chemkinToFoam),
    ExecutableProduct("chtMultiRegionFoam", :chtMultiRegionFoam),
    ExecutableProduct("coalChemistryFoam", :coalChemistryFoam),
    ExecutableProduct("coldEngineFoam", :coldEngineFoam),
    ExecutableProduct("collapseEdges", :collapseEdges),
    ExecutableProduct("combinePatchFaces", :combinePatchFaces),
    ExecutableProduct("compressibleInterFilmFoam", :compressibleInterFilmFoam),
    ExecutableProduct("compressibleInterFoam", :compressibleInterFoam),
    ExecutableProduct("compressibleMultiphaseInterFoam", :compressibleMultiphaseInterFoam),
    ExecutableProduct("createBaffles", :createBaffles),
    ExecutableProduct("createExternalCoupledPatchGeometry", :createExternalCoupledPatchGeometry),
    ExecutableProduct("createPatch", :createPatch),
    ExecutableProduct("datToFoam", :datToFoam),
    ExecutableProduct("decomposePar", :decomposePar),
    ExecutableProduct("deformedGeom", :deformedGeom),
    ExecutableProduct("dnsFoam", :dnsFoam),
    ExecutableProduct("DPMFoam", :DPMFoam),
    ExecutableProduct("driftFluxFoam", :driftFluxFoam),
    ExecutableProduct("dsmcFoam", :dsmcFoam),
    ExecutableProduct("dsmcInitialise", :dsmcInitialise),
    ExecutableProduct("electrostaticFoam", :electrostaticFoam),
    ExecutableProduct("engineCompRatio", :engineCompRatio),
    ExecutableProduct("engineFoam", :engineFoam),
    ExecutableProduct("engineSwirl", :engineSwirl),
    ExecutableProduct("equilibriumCO", :equilibriumCO),
    ExecutableProduct("equilibriumFlameT", :equilibriumFlameT),
    ExecutableProduct("extrude2DMesh", :extrude2DMesh),
    ExecutableProduct("extrudeMesh", :extrudeMesh),
    ExecutableProduct("extrudeToRegionMesh", :extrudeToRegionMesh),
    ExecutableProduct("faceAgglomerate", :faceAgglomerate),
    ExecutableProduct("financialFoam", :financialFoam),
    ExecutableProduct("fireFoam", :fireFoam),
    ExecutableProduct("flattenMesh", :flattenMesh),
    ExecutableProduct("fluent3DMeshToFoam", :fluent3DMeshToFoam),
    ExecutableProduct("fluentMeshToFoam", :fluentMeshToFoam),
    ExecutableProduct("foamDataToFluent", :foamDataToFluent),
    ExecutableProduct("foamDictionary", :foamDictionary),
    ExecutableProduct("foamFormatConvert", :foamFormatConvert),
    ExecutableProduct("foamListTimes", :foamListTimes),
    ExecutableProduct("foamMeshToFluent", :foamMeshToFluent),
    ExecutableProduct("foamSetupCHT", :foamSetupCHT),
    ExecutableProduct("foamToEnsight", :foamToEnsight),
    ExecutableProduct("foamToEnsightParts", :foamToEnsightParts),
    ExecutableProduct("foamToGMV", :foamToGMV),
    ExecutableProduct("foamToStarMesh", :foamToStarMesh),
    ExecutableProduct("foamToSurface", :foamToSurface),
    ExecutableProduct("foamToTetDualMesh", :foamToTetDualMesh),
    ExecutableProduct("foamToVTK", :foamToVTK),
    ExecutableProduct("gambitToFoam", :gambitToFoam),
    ExecutableProduct("gmshToFoam", :gmshToFoam),
    ExecutableProduct("icoFoam", :icoFoam),
    ExecutableProduct("ideasUnvToFoam", :ideasUnvToFoam),
    ExecutableProduct("insideCells", :insideCells),
    ExecutableProduct("interFoam", :interFoam),
    ExecutableProduct("interMixingFoam", :interMixingFoam),
    ExecutableProduct("interPhaseChangeFoam", :interPhaseChangeFoam),
    ExecutableProduct("kivaToFoam", :kivaToFoam),
    ExecutableProduct("laplacianFoam", :laplacianFoam),
    ExecutableProduct("magneticFoam", :magneticFoam),
    ExecutableProduct("mapFields", :mapFields),
    ExecutableProduct("mapFieldsPar", :mapFieldsPar),
    ExecutableProduct("mdEquilibrationFoam", :mdEquilibrationFoam),
    ExecutableProduct("mdFoam", :mdFoam),
    ExecutableProduct("mdInitialise", :mdInitialise),
    ExecutableProduct("mergeMeshes", :mergeMeshes),
    ExecutableProduct("mergeOrSplitBaffles", :mergeOrSplitBaffles),
    ExecutableProduct("mhdFoam", :mhdFoam),
    ExecutableProduct("mirrorMesh", :mirrorMesh),
    ExecutableProduct("mixtureAdiabaticFlameT", :mixtureAdiabaticFlameT),
    ExecutableProduct("modifyMesh", :modifyMesh),
    ExecutableProduct("moveDynamicMesh", :moveDynamicMesh),
    ExecutableProduct("moveEngineMesh", :moveEngineMesh),
    ExecutableProduct("moveMesh", :moveMesh),
    ExecutableProduct("MPPICFoam", :MPPICFoam),
    ExecutableProduct("mshToFoam", :mshToFoam),
    ExecutableProduct("multiphaseEulerFoam", :multiphaseEulerFoam),
    ExecutableProduct("multiphaseInterFoam", :multiphaseInterFoam),
    ExecutableProduct("netgenNeutralToFoam", :netgenNeutralToFoam),
    ExecutableProduct("noise", :noise),
    ExecutableProduct("nonNewtonianIcoFoam", :nonNewtonianIcoFoam),
    ExecutableProduct("objToVTK", :objToVTK),
    ExecutableProduct("orientFaceZone", :orientFaceZone),
    ExecutableProduct("particleFoam", :particleFoam),
    ExecutableProduct("particleTracks", :particleTracks),
    ExecutableProduct("patchSummary", :patchSummary),
    ExecutableProduct("pdfPlot", :pdfPlot),
    ExecutableProduct("PDRFoam", :PDRFoam),
    ExecutableProduct("PDRMesh", :PDRMesh),
    ExecutableProduct("pimpleFoam", :pimpleFoam),
    ExecutableProduct("pisoFoam", :pisoFoam),
    ExecutableProduct("plot3dToFoam", :plot3dToFoam),
    ExecutableProduct("polyDualMesh", :polyDualMesh),
    ExecutableProduct("porousSimpleFoam", :porousSimpleFoam),
    ExecutableProduct("postChannel", :postChannel),
    ExecutableProduct("postProcess", :postProcess),
    ExecutableProduct("potentialFoam", :potentialFoam),
    ExecutableProduct("potentialFreeSurfaceFoam", :potentialFreeSurfaceFoam),
    ExecutableProduct("reactingFoam", :reactingFoam),
    ExecutableProduct("reactingParcelFoam", :reactingParcelFoam),
    ExecutableProduct("reconstructPar", :reconstructPar),
    ExecutableProduct("reconstructParMesh", :reconstructParMesh),
    ExecutableProduct("redistributePar", :redistributePar),
    ExecutableProduct("refineHexMesh", :refineHexMesh),
    ExecutableProduct("refinementLevel", :refinementLevel),
    ExecutableProduct("refineMesh", :refineMesh),
    ExecutableProduct("refineWallLayer", :refineWallLayer),
    ExecutableProduct("removeFaces", :removeFaces),
    ExecutableProduct("renumberMesh", :renumberMesh),
    ExecutableProduct("rhoCentralFoam", :rhoCentralFoam),
    ExecutableProduct("rhoParticleFoam", :rhoParticleFoam),
    ExecutableProduct("rhoPimpleFoam", :rhoPimpleFoam),
    ExecutableProduct("rhoPorousSimpleFoam", :rhoPorousSimpleFoam),
    ExecutableProduct("rhoReactingBuoyantFoam", :rhoReactingBuoyantFoam),
    ExecutableProduct("rhoReactingFoam", :rhoReactingFoam),
    ExecutableProduct("rhoSimpleFoam", :rhoSimpleFoam),
    ExecutableProduct("rotateMesh", :rotateMesh),
    ExecutableProduct("sammToFoam", :sammToFoam),
    ExecutableProduct("scalarTransportFoam", :scalarTransportFoam),
    ExecutableProduct("selectCells", :selectCells),
    ExecutableProduct("setFields", :setFields),
    ExecutableProduct("setSet", :setSet),
    ExecutableProduct("setsToZones", :setsToZones),
    ExecutableProduct("setWaves", :setWaves),
    ExecutableProduct("shallowWaterFoam", :shallowWaterFoam),
    ExecutableProduct("simpleFoam", :simpleFoam),
    ExecutableProduct("simpleReactingParcelFoam", :simpleReactingParcelFoam),
    ExecutableProduct("singleCellMesh", :singleCellMesh),
    ExecutableProduct("smapToFoam", :smapToFoam),
    ExecutableProduct("snappyHexMesh", :snappyHexMesh),
    ExecutableProduct("solidDisplacementFoam", :solidDisplacementFoam),
    ExecutableProduct("solidEquilibriumDisplacementFoam", :solidEquilibriumDisplacementFoam),
    ExecutableProduct("splitCells", :splitCells),
    ExecutableProduct("splitMesh", :splitMesh),
    ExecutableProduct("splitMeshRegions", :splitMeshRegions),
    ExecutableProduct("sprayFoam", :sprayFoam),
    ExecutableProduct("SRFPimpleFoam", :SRFPimpleFoam),
    ExecutableProduct("SRFSimpleFoam", :SRFSimpleFoam),
    ExecutableProduct("star3ToFoam", :star3ToFoam),
    ExecutableProduct("star4ToFoam", :star4ToFoam),
    ExecutableProduct("steadyParticleTracks", :steadyParticleTracks),
    ExecutableProduct("stitchMesh", :stitchMesh),
    ExecutableProduct("subsetMesh", :subsetMesh),
    ExecutableProduct("surfaceAdd", :surfaceAdd),
    ExecutableProduct("surfaceAutoPatch", :surfaceAutoPatch),
    ExecutableProduct("surfaceBooleanFeatures", :surfaceBooleanFeatures),
    ExecutableProduct("surfaceCheck", :surfaceCheck),
    ExecutableProduct("surfaceClean", :surfaceClean),
    ExecutableProduct("surfaceCoarsen", :surfaceCoarsen),
    ExecutableProduct("surfaceConvert", :surfaceConvert),
    ExecutableProduct("surfaceFeatureConvert", :surfaceFeatureConvert),
    ExecutableProduct("surfaceFeatures", :surfaceFeatures),
    ExecutableProduct("surfaceFind", :surfaceFind),
    ExecutableProduct("surfaceHookUp", :surfaceHookUp),
    ExecutableProduct("surfaceInertia", :surfaceInertia),
    ExecutableProduct("surfaceLambdaMuSmooth", :surfaceLambdaMuSmooth),
    ExecutableProduct("surfaceMeshConvert", :surfaceMeshConvert),
    ExecutableProduct("surfaceMeshConvertTesting", :surfaceMeshConvertTesting),
    ExecutableProduct("surfaceMeshExport", :surfaceMeshExport),
    ExecutableProduct("surfaceMeshImport", :surfaceMeshImport),
    ExecutableProduct("surfaceMeshInfo", :surfaceMeshInfo),
    ExecutableProduct("surfaceMeshTriangulate", :surfaceMeshTriangulate),
    ExecutableProduct("surfaceOrient", :surfaceOrient),
    ExecutableProduct("surfacePointMerge", :surfacePointMerge),
    ExecutableProduct("surfaceRedistributePar", :surfaceRedistributePar),
    ExecutableProduct("surfaceRefineRedGreen", :surfaceRefineRedGreen),
    ExecutableProduct("surfaceSplitByPatch", :surfaceSplitByPatch),
    ExecutableProduct("surfaceSplitByTopology", :surfaceSplitByTopology),
    ExecutableProduct("surfaceSplitNonManifolds", :surfaceSplitNonManifolds),
    ExecutableProduct("surfaceSubset", :surfaceSubset),
    ExecutableProduct("surfaceToPatch", :surfaceToPatch),
    ExecutableProduct("surfaceTransformPoints", :surfaceTransformPoints),
    ExecutableProduct("temporalInterpolate", :temporalInterpolate),
    ExecutableProduct("tetgenToFoam", :tetgenToFoam),
    ExecutableProduct("thermoFoam", :thermoFoam),
    ExecutableProduct("topoSet", :topoSet),
    ExecutableProduct("transformPoints", :transformPoints),
    ExecutableProduct("twoLiquidMixingFoam", :twoLiquidMixingFoam),
    ExecutableProduct("viewFactorsGen", :viewFactorsGen),
    ExecutableProduct("vtkUnstructuredToFoam", :vtkUnstructuredToFoam),
    ExecutableProduct("wallFunctionTable", :wallFunctionTable),
    ExecutableProduct("writeMeshObj", :writeMeshObj),
    ExecutableProduct("XiEngineFoam", :XiEngineFoam),
    ExecutableProduct("XiFoam", :XiFoam),
    ExecutableProduct("zipUpMesh", :zipUpMesh),
    FileProduct("share/openfoam/etc", :openfoam_etc),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("flex_jll"),
    Dependency("SCOTCH_jll"; compat=SCOTCH_COMPAT_VERSION),
    Dependency("PTSCOTCH_jll"),
    Dependency("METIS_jll"),
    Dependency("Zlib_jll"),
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version=v"5")
