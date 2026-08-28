# Build script for Musica_jll
#
# This recipe needs a BinaryBuilderBase.jl version newer than any tagged
# release (specifically, a version that includes
# https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/473, which
# fixes GCC 15.2 support on aarch64-apple-darwin). CI already gets this
# through Yggdrasil's own ../../.ci/Project.toml, which pins
# BinaryBuilderBase.jl to its master branch. To match CI locally, run Julia
# with that same project instead of a bare `julia build_tarballs.jl`:
#
#   julia --project -e 'import Pkg; Pkg.instantiate()'
#
# (`--project` resolves to `../../.ci` through a symlink in the top-level
# directory.)
#
# To test locally:
#   julia --project=../../.ci build_tarballs.jl --verbose --debug
#
# To build for a specific platform:
#   julia --project=../../.ci build_tarballs.jl x86_64-linux-gnu-cxx11
#
# To create a local installation
#   julia --project=../../.ci build_tarballs.jl --deploy=local "aarch64-apple-darwin-julia_version+1.11"

using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

name = "Musica"
version = v"0.16.7"

# Collection of sources required to build Musica
sources = [
    GitSource("https://github.com/NCAR/musica.git",
              "71abef833c92d22756b47861d712eb162a4bc137")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/musica

# Needs cmake >= 3.24 provided by jll
apk del cmake

# Update Ninja — the sandbox's built-in ninja (1.9) is too old for Fortran support
cp ${host_prefix}/bin/ninja /usr/bin/ninja

if [[ "${target}" == *-apple-* ]]; then
    # Install libdispatch. This is required for the MacOS linker.
    # It should probably have been put into the root file system.
    # This requires GCC 14 or later.
    apk add libdispatch libdispatch-dev --repository=http://dl-cdn.alpinelinux.org/alpine/v3.17/community
fi

# Configure MUSICA with Julia wrapper enabled
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}" \
    -DJulia_PREFIX=${prefix} \
    -DMUSICA_BUILD_C_CXX_INTERFACE=ON \
    -DMUSICA_ENABLE_JULIA=ON \
    -DMUSICA_ENABLE_MICM=ON \
    -DMUSICA_ENABLE_TUVX=ON \
    -DMUSICA_ENABLE_CARMA=OFF \
    -DMUSICA_ENABLE_TESTS=OFF \
    -DMUSICA_ENABLE_INSTALL=ON \
    -DMUSICA_BUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
    -DTUVX_BUILD_CLI=OFF

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE

# On Windows, CMake installs DLLs for LIBRARY targets to lib/ instead of bin/
# BinaryBuilder requires all DLLs to be in bin/
if [[ "${target}" == *-mingw* ]]; then
    mv -vf "${prefix}/lib/"*.dll "${libdir}/" || true
fi
"""

sources, script = require_macos_sdk("14.5", sources, script)

# grab all of the platforms supported by libjulia
include(joinpath(YGGDRASIL_DIR, "L", "libjulia", "common.jl"))
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

# libcxxwrap_julia_jll does not provide artifacts for armv6l, armv7l, or i686-linux-musl
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "armv7l", platforms)
filter!(p -> !(arch(p) == "i686" && libc(p) == "musl"), platforms)

# NetCDFF_jll ships no linkable import library on Windows (see N/NetCDFF/build_tarballs.jl), so drop it
filter!(!Sys.iswindows, platforms)

# TUV-x does not call MPI directly, but it links against a parallel
# HDF5-enabled NetCDF, so it links explicitly against MPI libraries.
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
    """

platforms, platform_dependencies = MPI.augment_platforms(platforms)

# MPIABI is broken on macOS for this toolchain (self-conflicting -march guard / missing libBlocksRuntime, regardless of Julia version)
filter!(p -> !(Sys.isapple(p) && p["mpi"] == "mpiabi"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libmusica_julia", :libmusica_julia),
    LibraryProduct("libmusica", :libmusica),
    LibraryProduct("libmechanism_configuration", :libmechanism_configuration),
    LibraryProduct("libyaml-cpp", :libyaml_cpp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("libjulia_jll"),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.9"),
    HostBuildDependency(PackageSpec(name="CMake_jll", version="3.31.9")),
    HostBuildDependency(PackageSpec(name="Ninja_jll", uuid="76642167-d241-5cee-8c94-7a494e8cb7b7")),
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"); compat="401.1000.101"),
    Dependency(PackageSpec(name="NetCDFF_jll", uuid="78e728a9-57fe-5d11-897c-5014b89e5f84"); compat="4.6.4"),
    Dependency("HDF5_jll"; compat="2.2.1"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]
append!(dependencies, platform_dependencies)

# Build the tarballs
build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    augment_platform_block,
    julia_compat=libjulia_julia_compat(julia_versions),
    preferred_gcc_version=v"15.2", # v"15" excludes 15.2.0-iains (rounds down to broken 12.0.1-iains on aarch64-apple-darwin)
    preferred_llvm_version=v"17", lock_microarchitecture=false, # matches L/libjulia/common.jl; fixes macOS -march guard conflict and missing libBlocksRuntime/libdispatch
    dont_dlopen=true
)
