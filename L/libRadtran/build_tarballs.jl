# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "libRadtran"
version = v"2.0.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("http://www.libradtran.org/download/libRadtran-$(version).tar.gz", "eb840e00f2b59648e77775df83d8ae2337880cec155d145228cd65365e3c816f")
]

# Bash recipe for building across all platforms
script = raw"""
# Find MPI implementation
grep -iq MPICH $prefix/include/mpi.h && mpi_impl=mpich
grep -iq MPItrampoline $prefix/include/mpi.h && mpi_impl=mpitrampoline
grep -iq OpenMPI $prefix/include/mpi.h && mpi_impl=openmpi

cd ${includedir}
case $mpi_impl in
mpich)
    # TODO: Implement this. We need to store the mpi.f90 that is generated when MPICH is built.
    ;;
mpitrampoline)
    wget https://raw.githubusercontent.com/eschnett/MPItrampoline/v5.0.1/include/mpi.F90
    # gfortran -DGCC_ATTRIBUTES_NO_ARG_CHECK= -fallow-argument-mismatch -fcray-pointer -O2 -c mpi.F90
    gfortran -DGCC_ATTRIBUTES_NO_ARG_CHECK= -fcray-pointer -O2 -c mpi.F90
    ;;
openmpi)
    ;;
esac
cd $WORKSPACE/srcdir/libRadtran-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
touch lib/libRadtran.so
make clean
make
make install
install -Dvm 755 lib/libRadtran.so "${libdir}/libRadtran.${dlext}"
install_license COPYING
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions([
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; )
])
platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && Sys.isfreebsd(p)), platforms)

# Disable MPICH + libgfortran3 because `mpi.mod` is incompatible:
platforms = filter(p -> !(p["mpi"] == "mpich" && libgfortran_version(p) == v"3"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("make_angresfunc", :make_angresfunc),
    ExecutableProduct("ssradar", :ssradar),
    ExecutableProduct("uvspec_mpi", :uvspec_mpi),
    ExecutableProduct("read_Stamnes_tab", :read_Stamnes_tab),
    ExecutableProduct("zenith", :zenith),
    ExecutableProduct("noon", :noon),
    ExecutableProduct("sza2time", :sza2time),
    ExecutableProduct("angres", :angres),
    ExecutableProduct("uvspec", :uvspec),
    ExecutableProduct("vac2air", :vac2air),
    ExecutableProduct("vrs_ocean_albedo", :vrs_ocean_albedo),
    ExecutableProduct("make_slitfunction", :make_slitfunction),
    ExecutableProduct("pmom", :pmom),
    ExecutableProduct("phase", :phase),
    ExecutableProduct("sofi", :sofi),
    ExecutableProduct("conv", :conv),
    ExecutableProduct("mie", :mie),
    ExecutableProduct("integrate", :integrate),
    ExecutableProduct("snowalbedo", :snowalbedo),
    ExecutableProduct("spline", :spline),
    ExecutableProduct("cldprp", :cldprp),
    ExecutableProduct("plkavg", :plkavg),
    ExecutableProduct("time2sza", :time2sza),
    ExecutableProduct("uvspecfunction", :uvspecfunction),
    LibraryProduct("libRadtran", :libRadtran),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2")
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; augment_platform_block, julia_compat="1.6")
