using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "OpenSWPC"
version_string = "26.09.2"
version = VersionNumber(version_string)

sources = [
    GitSource("https://github.com/OpenSWPC/OpenSWPC.git",
              "2d59272225f4e2c8d164dc65427673a9a75723e6"; tag=version_string),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenSWPC
for p in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${p}
done
cd src

FFLAGS="-O2 -cpp -ffree-line-length-none -I${includedir}"
if [[ ${bb_full_target} == *mpiabi* ]]; then
    MPILIB="-lmpif -lmpi_abi"
elif [[ ${bb_full_target} == *mpich* ]]; then
    MPILIB="-lmpifort -lmpi"
elif [[ ${bb_full_target} == *mpitrampoline* ]]; then
    # MPItrampoline's mpi.mod has no explicit interfaces, so the REAL(4)/REAL(8) buffer calls need this
    FFLAGS+=" -fcray-pointer -fallow-argument-mismatch"
    MPILIB="-lmpitrampoline"
elif [[ ${bb_full_target} == *openmpi* ]]; then
    # OpenMPI_jll installs mpi.mod next to the libraries
    FFLAGS+=" -I${libdir}"
    MPILIB="-lmpi_usempif08 -lmpi_usempi_ignore_tkr -lmpi_mpifh -lmpi"
elif [[ ${bb_full_target} == *microsoftmpi* ]]; then
    # the executables abort at load time with "32 bit pseudo relocation out of range" otherwise
    FFLAGS+=" -fallow-invalid-boz -fallow-argument-mismatch -Wl,--disable-runtime-pseudo-reloc"
    MPILIB="-lmsmpi"
fi

make -j${nproc} FC=${FC} FFLAGS="${FFLAGS}" NCINC="-I${includedir}" NCLIB="-L${libdir}" \
    NETCDF="-lnetcdff -lnetcdf ${MPILIB}" all

for exe in swpc_3d swpc_psv swpc_sh diff_snp fdmcond fs2grd gen_rmed3d grdsnp ll2xy mapregion qmodel_tau read_snp wvconv xy2ll; do
    install -Dvm 755 ../bin/${exe}.x "${bindir}/${exe}${exeext}"
done
install_license ../LICENSE
"""

platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)
# BinaryBuilder finds no NetCDFF/MPICH/HDF5 artifacts for the libgfortran3/4 variants
filter!(p -> libgfortran_version(p) >= v"5", platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    ExecutableProduct("swpc_3d", :swpc_3d),
    ExecutableProduct("swpc_psv", :swpc_psv),
    ExecutableProduct("swpc_sh", :swpc_sh),
    ExecutableProduct("diff_snp", :diff_snp),
    ExecutableProduct("fdmcond", :fdmcond),
    ExecutableProduct("fs2grd", :fs2grd),
    ExecutableProduct("gen_rmed3d", :gen_rmed3d),
    ExecutableProduct("grdsnp", :grdsnp),
    ExecutableProduct("ll2xy", :ll2xy),
    ExecutableProduct("mapregion", :mapregion),
    ExecutableProduct("qmodel_tau", :qmodel_tau),
    ExecutableProduct("read_snp", :read_snp),
    ExecutableProduct("wvconv", :wvconv),
    ExecutableProduct("xy2ll", :xy2ll),
]

dependencies = [
    Dependency("NetCDF_jll"; compat="401.1000.101"),
    Dependency("NetCDFF_jll"; compat="4.6.4"),
    Dependency("CompilerSupportLibraries_jll"; compat="1.0.5"),
    # MPIABI provides only the C bindings
    Dependency("mpif_jll"; compat="1.0.1", platforms=filter(p -> p["mpi"] == "mpiabi", platforms)),
]
append!(dependencies, platform_dependencies)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# -fallow-argument-mismatch and -fallow-invalid-boz need GCC 10
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"10")
