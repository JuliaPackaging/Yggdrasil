# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
using Base.BinaryPlatforms
const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "easi"
version = v"1.7.0"

sources = [
    GitSource("https://github.com/SeisSol/easi.git",
              "f668a64afa61191d8c9ae4e6adf47aecd2529e00"),  # v1.7.0
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/easi*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/windows.patch

# ASAGI is located with pkg-config, as SeisSol 1.3 does, so that easi's exported targets do not
# refer to the CMake target asagi::asagi-shared of the ASAGI CMake package.
cmake_args=(-DASAGI=ON
            -DCMAKE_DISABLE_FIND_PACKAGE_asagi=ON
            -DNetCDF_INCLUDE_DIR=${includedir})
if [[ "${target}" == *-mingw* ]]; then
    # the NetCDF and Lua libraries are called libnetcdf-<soversion>.dll and lua54.dll on Windows
    cmake_args+=(-DLUA_LIBRARY=${libdir}/lua54.dll)
else
    cmake_args+=(-DLUA_LIBRARY=${libdir}/liblua.${dlext}
                 -DNetCDF_LIBRARY=${libdir}/libnetcdf.${dlext})
fi

cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON \
    -D_FILESYSTEM_NATIVE=1 \
    -DLUA=ON \
    "${cmake_args[@]}"
cmake --build build --parallel ${nproc}
cmake --install build
install_license LICENSE
"""

# std::filesystem needs macOS >= 10.15
sources, script = require_macos_sdk("11.0", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())
platforms, platform_dependencies = MPI.augment_platforms(platforms)

augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""

products = [
    LibraryProduct("libeasi", :libeasi),
]

dependencies = [
    Dependency("ASAGI_jll"; compat = "1.0.1"),
    Dependency("CompilerSupportLibraries_jll"; platforms = filter(!Sys.isapple, platforms)),
    Dependency("HDF5_jll"; compat = "2.2.2"),
    Dependency("LLVMOpenMP_jll"; platforms = filter(Sys.isapple, platforms)),
    Dependency("Lua_jll"; compat = "~5.4.9"),
    Dependency("NetCDF_jll"; compat = "401.1000.101"),
    Dependency("yaml_cpp_jll"; compat = "0.9.0"),
]
append!(dependencies, platform_dependencies)

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the shared libraries.
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block, julia_compat = "1.6", preferred_gcc_version = v"9")
