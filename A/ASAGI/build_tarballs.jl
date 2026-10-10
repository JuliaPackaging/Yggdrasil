# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "ASAGI"
version = v"1.0.1"

sources = [
    GitSource("https://github.com/TUM-I5/ASAGI.git",
              "132da427f297ae0a31ff941874cc464a4feeb985"),
    # git submodule of ASAGI (GitSource does not fetch submodules)
    GitSource("https://github.com/TUM-I5/utils.git",
              "3f1f476d42621dac848a952b50956b6e48f7c92b"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir
cp -a utils/. ASAGI/submodules/utils/
cd ASAGI
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/portability.patch

# the NetCDF library is called libnetcdf-<soversion>.dll on Windows: let CMake find it there
netcdf_args=(-DNetCDF_INCLUDE_DIR=${includedir})
if [[ "${target}" != *-mingw* ]]; then
    netcdf_args+=(-DNetCDF_LIBRARY=${libdir}/libnetcdf.${dlext})
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHARED_LIB=ON \
    -DSTATIC_LIB=OFF \
    -DFORTRAN_SUPPORT=OFF \
    -DNONUMA=ON \
    "${netcdf_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSES/*
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

products = [
    LibraryProduct("libasagi", :libasagi),
]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"; platforms = filter(!Sys.isapple, platforms)),
    Dependency("HDF5_jll"; compat = "2.2.2"),
    Dependency("LLVMOpenMP_jll"; platforms = filter(Sys.isapple, platforms)),
    Dependency("NetCDF_jll"; compat = "401.1000.101"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat = "1.6", preferred_gcc_version = v"9")
