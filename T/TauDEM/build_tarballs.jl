# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TauDEM"
version = v"5.3.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/dtarb/TauDEM/archive/refs/tags/v$version.tar.gz", "2ba4659cdb6e6ef06194cfeb3947ed228d318778f75a176fa030978e2570058d"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TauDEM-*

#this has been added on master, so can probably get rid of next version release
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/add-cxx-standard.patch

if [[ ${target} == *mingw* ]]; then
    atomic_patch -p1 ${WORKSPACE}/srcdir/patches/mingw-enable-fortran.patch
fi

cd src
mkdir build && cd build

cmake .. \
-DCMAKE_INSTALL_PREFIX=${prefix} \
-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())


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
    Dependency(PackageSpec(name="MPICH_jll", uuid="7cb0a576-ebde-5e09-9194-50597f1243b4"))
    Dependency(PackageSpec(name="MicrosoftMPI_jll", uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0", julia_compat="1.6")
