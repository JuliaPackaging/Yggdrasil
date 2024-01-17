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
LDFLAGS=""
for dir in "" "/dummy" "/mpi-system"; do     LDFLAGS="${LDFLAGS} -Wl,-rpath-link=${PWD}/platforms/linux64GccDPInt32Opt/lib${dir}"; done

echo "export SCOTCH_VERSION=6.1.0" > etc/config.sh/scotch
echo "export SCOTCH_ARCH_PATH=${prefix}"      >> etc/config.sh/scotch

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

source etc/bashrc || true

./Allwmake -j${nproc}

mkdir -p "${libdir}" "${bindir}" "${prefix}/share/openfoam"
cp platforms/linux64GccDPInt32Opt/lib/{,dummy/,mpi-system/}*.${dlext}* "${libdir}/."
cp platforms/linux64GccDPInt32Opt/bin/* "${bindir}/."
cp -r etc/ "${prefix}/share/openfoam/."
exit
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
    LibraryProduct("libscotchDecomp", :libscotchDecomp),
    LibraryProduct("liblumpedPointMotion", :liblumpedPointMotion),
    LibraryProduct("libchemistryModel", :libchemistryModel),
    LibraryProduct("libthermoTools", :libthermoTools),
    LibraryProduct("libhelpTypes", :libhelpTypes),
    LibraryProduct("libfiniteArea", :libfiniteArea),
    LibraryProduct("libextrude2DMesh", :libxtrude2DMesh),
    LibraryProduct("libincompressibleMultiphaseSystems", :libincompressibleMultiphaseSystems),
    LibraryProduct("libsaturationModel", :libsaturationModel),
    LibraryProduct("libpotential", :libpotential),
    LibraryProduct("libMGridGen", :libMGridGen),
    LibraryProduct("libblockMesh", :libblockMesh),
    LibraryProduct("libregionFaModels", :libregionFaModels),
    LibraryProduct("libtwoPhaseReactingTurbulenceModels", :libtwoPhaseReactingTurbulenceModels),
    LibraryProduct("libsixDoFRigidBodyState", :libsixDoFRigidBodyState),
    LibraryProduct("libradiationModels", :libradiationModels),
    LibraryProduct("libgeometricVoF", :libgeometricVoF),
    LibraryProduct("libcompressibleTwoPhaseSystem", :libcompressibleTwoPhaseSystem),
    LibraryProduct("libincompressibleTurbulenceModels", :libincompressibleTurbulenceModels),
    LibraryProduct("libDPMTurbulenceModels", :libDPMTurbulenceModels),
    LibraryProduct("libfaReconstruct", :libfaReconstruct),
    LibraryProduct("libcombustionModels", :libcombustionModels),
    LibraryProduct("libVoFphaseCompressibleTurbulenceModels", :libVoFphaseCompressibleTurbulenceModels),
    LibraryProduct("libdecompose", :libdecompose),
    LibraryProduct("libmultiphaseSystem", :libmultiphaseSystem),
    LibraryProduct("libsolverFunctionObjects", :libsolverFunctionObjects),
    LibraryProduct("libphaseFunctionObjects", :libphaseFunctionObjects),
    LibraryProduct("libsolidChemistryModel", :libsolidChemistryModel),
    LibraryProduct("libtwoPhaseProperties", :libtwoPhaseProperties),
    LibraryProduct("libregionCoupling", :libregionCoupling),
    LibraryProduct("libfieldFunctionObjects", :libfieldFunctionObjects),
    LibraryProduct("libcompressibleTwoPhaseMixtureTurbulenceModels", :libcompressibleTwoPhaseMixutreTurublenceModels),
    LibraryProduct("libmultiphaseInterFoam", :libmultiphaseInterFoam),
    LibraryProduct("libsolidParticle", :libsolidParticle),
    LibraryProduct("libkahipDecomp", :libkahipDecomp),
    LibraryProduct("libgenericPatchFields", :libgenericPatchFields),
    LibraryProduct("libsurfMesh", :libsurfMesh),
    LibraryProduct("librigidBodyMeshMotion", :librigidBodyMeshMotion),
    LibraryProduct("libdriftFluxTransportModels", :libdriftFluxTransportModels),
    LibraryProduct("liblagrangianSpray", :liblagrangianSpray),
    LibraryProduct("libsurfaceFilmDerivedFvPatchFields", :libsurfaceFilmDerivedFvPatchFields),
    LibraryProduct("libspecie", :libspecie),
    LibraryProduct("libpairPatchAgglomeration", :libpairPatchAgglomeration),
    LibraryProduct("libdynamicMesh", :libdynamicMesh),
    LibraryProduct("libVoFphaseTurbulentTransportModels", :libVoFphaseTurbulentTransportModels),
    LibraryProduct("libfvMotionSolvers", :libfvMotionSolvers),
    LibraryProduct("libimmiscibleIncompressibleTwoPhaseMixture", :libimmiscibleIncompressibleTwoPhaseMixture),
    LibraryProduct("libcompressibleTransportModels", :libcompressibleTransportModels),
    LibraryProduct("libptscotchDecomp", :libptscotchDecomp),
    LibraryProduct("libcompressibleTurbulenceModels", :libcompressibleTurbulenceModels),
    LibraryProduct("libcoalCombustion", :libcoalCombustion),
    LibraryProduct("libphaseTemperatureChangeTwoPhaseMixtures", :libphaseTemperatureChangeTwoPhaseMixtures),
    LibraryProduct("libsnappyHexMesh", :libsnappyHexMesh),
    LibraryProduct("libturbulenceModelSchemes", :libturbulenceModelSchemes),
    LibraryProduct("libreconstruct", :libreconstruct),
    LibraryProduct("libfluidThermophysicalModels", :libfluidThermophysicalModels),
    LibraryProduct("libwaveModels", :libwaveModels),
    LibraryProduct("libdistributionModels", :libdistributionModels),
    LibraryProduct("libdistributed", :libdistributed),
    LibraryProduct("libcompressibleMultiPhaseTurbulenceModels", :libcompressibleMultiPhaseTurbulenceModels),
    LibraryProduct("libadjointOptimisation", :libadjointOptimisation),
    LibraryProduct("libDSMC", :libDSMC),
    LibraryProduct("librigidBodyDynamics", :librigidBodyDynamics),
    LibraryProduct("liblagrangianFunctionObjects", :liblagrangianFunctionObjects),
    LibraryProduct("libincompressibleInterPhaseTransportModels", :libincompressibleInterPhaseTransportModels),
    LibraryProduct("libextrudeModel", :libextrudeModel),
    LibraryProduct("libsolidSpecie", :libsolidSpecie),
    LibraryProduct("libphaseChangeTwoPhaseMixtures", :libphaseChangeTwoPhaseMixtures),
    LibraryProduct("libmeshTools", :libmeshTools),
    LibraryProduct("libmultiphaseMixtureThermo", :libmultiphaseMixtureThermo),
    LibraryProduct("libsurfaceFeatureExtract", :libsurfaceFeatureExtract),
    LibraryProduct("libsampling", :libsampling),
    LibraryProduct("libdecompositionMethods", :libdecompositionMethods),
    LibraryProduct("libSLGThermo", :libSLGThermo),
    LibraryProduct("libphaseCompressibleTurbulenceModels", :libphaseCompressibleTurbulenceModels),
    LibraryProduct("libreactingMultiphaseSystem", :libreactingMultiphaseSystem),
    LibraryProduct("libfileFormats", :libfileFormats),
    LibraryProduct("libtwoPhaseMixtureThermo", :libtwoPhaseMixtureThermo),
    LibraryProduct("libtwoPhaseMixture", :libtwoPhaseMixture),
    LibraryProduct("libreactingTwoPhaseSystem", :libreactingTwoPhaseSystem),
    LibraryProduct("libpyrolysisModels", :libpyrolysisModels),
    LibraryProduct("libsixDoFRigidBodyMotion", :libsixDoFRigidBodyMotion),
    LibraryProduct("libmolecule", :libmolecule),
    LibraryProduct("libmolecularMeasurements", :libmolecularMeasurements),
    LibraryProduct("libfaOptions", :libfaOptions),
    LibraryProduct("libalphaFieldFunctions", :libalphaFieldFunctions),
    LibraryProduct("libforces", :libforces),
    LibraryProduct("libfiniteVolume", :libfiniteVolume),
    LibraryProduct("librhoCentralFoam", :librhoCentralFoam),
    LibraryProduct("libtabulatedWallFunctions", :libtabulatedWallFunctions),
    LibraryProduct("libconversion", :libconversion),
    LibraryProduct("libpdrFields", :libpdrFields),
    LibraryProduct("libdriftFluxRelativeVelocityModels", :libdriftFluxRelativeVelocityModels),
    LibraryProduct("libatmosphericModels", :libatmosphericModels),
    LibraryProduct("libincompressibleTransportModels", :libincompressibleTransportModels),
    LibraryProduct("liblagrangian", :liblagrangian),
    LibraryProduct("libtwoPhaseSurfaceTension", :libtwoPhaseSurfaceTension),
    LibraryProduct("liblagrangianTurbulence", :liblagrangianTurbulence),
    LibraryProduct("librenumberMethods", :librenumberMethods),
    LibraryProduct("libsolidThermo", :libsolidThermo),
    LibraryProduct("libreactionThermophysicalModels", :libreactionThermophysicalModels),
    LibraryProduct("liblaminarFlameSpeedModels", :liblaminarFlameSpeedModels),
    LibraryProduct("libinitialisationFunctionObjects", :libinitialisationFunctionObjects),
    LibraryProduct("libbarotropicCompressibilityModel", :libbarotropicCompressibilityModel),
    LibraryProduct("libODE", :libODE),
    LibraryProduct("libregionModels", :libregionModels),
    LibraryProduct("liblaserDTRM", :liblaserDTRM),
    LibraryProduct("libthermalBaffleModels", :libthermalBaffleModels),
    LibraryProduct("libtopoChangerFvMesh", :libtopoChangerFvMesh),
    LibraryProduct("liboverset", :liboverset),
    LibraryProduct("libturbulenceModels", :libturbulenceModels),
    LibraryProduct("libfvOptions", :libfvOptions),
    LibraryProduct("libmetisDecomp", :libmetisDecomp),
    LibraryProduct("libPstream", :libPstream),
    LibraryProduct("libengine", :libengine),
    LibraryProduct("libdynamicFvMesh", :libdynamicFvMesh),
    LibraryProduct("liblagrangianIntermediate", :liblagrangianIntermediate),
    LibraryProduct("libutilityFunctionObjects", :libutilityFunctionObjects),
    LibraryProduct("libthermophysicalProperties", :libthermophysicalProperties),
    LibraryProduct("libsurfaceFilmModels", :libsurfaceFilmModels),
    LibraryProduct("libinterfaceProperties", :libinterfaceProperties),
    LibraryProduct("libfaDecompose", :libfaDecompose),
    LibraryProduct("libinterfaceTrackingFvMesh", :libinterfaceTrackingFvMesh),
    LibraryProduct("libOpenFOAM", :libOpenFOAM)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="flex_jll", uuid="48a596b8-cc7a-5e48-b182-65f75e8595d0"))
    Dependency(PackageSpec(name="SCOTCH_jll", uuid="a8d0f55d-b80e-548d-aff6-1a04c175f0f9"))
    Dependency(PackageSpec(name="PTSCOTCH_jll", uuid="b3ec0f5a-9838-5c9b-9e77-5f2c6a4b089f"))
    Dependency(PackageSpec(name="METIS_jll", uuid="d00139f3-1899-568f-a2f0-47f597d42d70"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
                augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"12.1.0")
