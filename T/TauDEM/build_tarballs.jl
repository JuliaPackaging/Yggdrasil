# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "TauDEM"
version = v"5.3.8"
taudem_version = v"5.3.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/dtarb/TauDEM/archive/refs/tags/v$(taudem_version).tar.gz",
                  "2ba4659cdb6e6ef06194cfeb3947ed228d318778f75a176fa030978e2570058d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TauDEM-*

#this has been added on master, so can probably get rid of next version release
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/add-cxx-standard.patch
# Explicitly cast initial values of `float` array to `float` values
atomic_patch -p1 ../patches/float-list-init.patch
# Replace MPI 1 calls that were removed from MPI 3
atomic_patch -p1 ../patches/mpi3.patch
# Fix linking to MPI libraries
atomic_patch -p1 ../patches/cmake-link-mpi.patch

cd src
mkdir build && cd build

# Adapted from Erik Schnetter's build for AMReX
ARGS=()
if [[ "$target" == *-apple-* ]]; then
    if grep -q MPICH_NAME ${prefix}/include/mpi.h; then
        # MPICH's pkgconfig file "mpich.pc" lists these options:
        #     Libs:     -framework OpenCL -Wl,-flat_namespace -Wl,-commons,use_dylibs -L${libdir} -lmpi -lpmpi -lm    -lpthread
        #     Cflags:   -I${includedir}
        # cmake doesn't know how to handle the "-framework OpenCL" option
        # and wants to use "-framework" as a stand-alone option. This fails,
        # and cmake concludes that MPI is not available.
        for lang in C CXX; do
            ARGS+=(
                -DMPI_${lang}_ADDITIONAL_INCLUDE_DIRS=''
                -DMPI_${lang}_LIBRARIES='-Wl,-flat_namespace;-Wl,-commons,use_dylibs;-lmpi;-lpmpi'
            )
        done
    elif grep -q MPItrampoline ${prefix}/include/mpi.h; then
        for lang in C CXX; do
            ARGS+=(
                -DMPI_${lang}_ADDITIONAL_INCLUDE_DIRS=''
                -DMPI_${lang}_LIBRARIES='-lmpitrampoline'
            )
        done
    fi
elif [[ "$target" == x86_64-w64-mingw32 ]]; then
    ARGS+=(
        -DMPI_HOME=${prefix}
        -DMPI_GUESS_LIBRARY_NAME=MSMPI
    )
    if [[ "${target}" == x86_64-* ]]; then
        for lang in C CXX; do
            ARGS+=(-DMPI_${lang}_LIBRARIES=msmpi64)
        done
    fi
fi

cmake .. \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    "${ARGS[@]}"

make -j${nproc}
make install
"""

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# Disable OpenMPI since it doesn't build. (This could probably be fixed.)
platforms = filter(p -> p["mpi"] ≠ "openmpi", platforms)

# Avoid platforms where the MPI implementation isn't supported
# OpenMPI
platforms = filter(p -> !(p["mpi"] == "openmpi" && arch(p) == "armv6l" && libc(p) == "glibc"), platforms)
# MPItrampoline
platforms = filter(p -> !(p["mpi"] == "mpitrampoline" && libc(p) == "musl"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("d8hdisttostrm", :d8hdisttostrm),
    ExecutableProduct("gagewatershed", :gagewatershed),
    ExecutableProduct("peukerdouglas", :peukerdouglas),
    ExecutableProduct("dinfrevaccum", :dinfrevaccum),
    ExecutableProduct("slopeavedown", :slopeavedown),
    ExecutableProduct("dinfdecayaccum", :dinfdecayaccum),
    ExecutableProduct("gridnet", :gridnet),
    ExecutableProduct("aread8", :aread8),
    ExecutableProduct("moveoutletstostrm", :moveoutletstostrm),
    ExecutableProduct("slopearea", :slopearea),
    ExecutableProduct("slopearearatio", :slopearearatio),
    ExecutableProduct("dinfavalanche", :dinfavalanche),
    ExecutableProduct("dinfflowdir", :dinfflowdir),
    ExecutableProduct("dinfdistdown", :dinfdistdown),
    ExecutableProduct("dinfupdependence", :dinfupdependence),
    ExecutableProduct("d8flowdir", :d8flowdir),
    ExecutableProduct("dinfconclimaccum", :dinfconclimaccum),
    ExecutableProduct("streamnet", :streamnet),
    ExecutableProduct("d8flowpathextremeup", :d8flowpathextremeup),
    ExecutableProduct("dinftranslimaccum", :dinftranslimaccum),
    ExecutableProduct("dropanalysis", :dropanalysis),
    ExecutableProduct("areadinf", :areadinf),
    ExecutableProduct("dinfdistup", :dinfdistup),
    ExecutableProduct("lengtharea", :lengtharea),
    ExecutableProduct("pitremove", :pitremove),
    ExecutableProduct("threshold", :threshold)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GDAL_jll", uuid="a7073274-a066-55f0-b90d-d619367d196c"))
]
append!(dependencies, platform_dependencies)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat="1.6", preferred_gcc_version = v"7.1.0")
