# Build script for Musica_jll
# To test locally:
#   julia build_tarballs.jl --verbose --debug
#
# To build for a specific platform:
#   julia build_tarballs.jl x86_64-linux-gnu-cxx11
#
# To create a local installation 
#  julia build_tarballs.jl --deploy=local "aarch64-apple-darwin-julia_version+1.11"

import Pkg
# https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/473
# allows for gcc 15.2 to be used. It's not yet in the released version of BinaryBuilderBase.jl, 
# but we need it to build Musica on aarch64-apple-darwin (M1/M2) because the default gcc 12.0.1-iains is broken for that platform.
Pkg.add(url="https://github.com/JuliaPackaging/BinaryBuilderBase.jl", rev="edf4a8fab7cfbf0bb131eb9e7be4d6ca31fa5f9f")

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

# On macOS, the darwin `ld` bundled with newer GCC shards (needed for SDK 14.5
# support) is missing libBlocksRuntime/libdispatch and can't even run. clang
# already links C++ fine via lld on this platform, so swap gfortran/collect2's
# linker for the same lld binary. lld needs -arch/-platform_version explicitly,
# since collect2 doesn't pass them the way it would for the legacy ld it thinks
# it's calling.
EXTRA_LD_FLAGS=""
if [[ "${target}" == *-apple-darwin* ]]; then
    LLD_PATH=$(find /opt -iname "*-ld64.lld" -type f 2>/dev/null | head -1)
    if [[ -n "${LLD_PATH}" ]]; then
        cp -v "${LLD_PATH}" "/opt/${target}/bin/${target}-ld"
    fi
    case "${target}" in
        x86_64-apple-darwin*) LD_ARCH="x86_64" ;;
        aarch64-apple-darwin*) LD_ARCH="arm64" ;;
    esac
    EXTRA_LD_FLAGS="-Wl,-arch,${LD_ARCH} -Wl,-platform_version,macos,${macosx_deployment_target},${macos_sdk_version}"
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
    -DTUVX_BUILD_CLI=OFF \
    -DCMAKE_EXE_LINKER_FLAGS="${EXTRA_LD_FLAGS}" \
    -DCMAKE_SHARED_LINKER_FLAGS="${EXTRA_LD_FLAGS}"

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
