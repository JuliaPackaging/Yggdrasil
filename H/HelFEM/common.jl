using BinaryBuilder, Pkg

name = "HelFEM"
version = VersionNumber(0, 1, julia_version.minor)
sources = [
    GitSource("https://github.com/mortenpi/HelFEM.git", "a4d3b2e6f16f7f7953afd5f69a44257a65c5b131"),
]

script = raw"""
cp -v ${WORKSPACE}/srcdir/HelFEM/julia/CMake.system ${WORKSPACE}/srcdir/HelFEM/CMake.system

# Set up some platform specific CMake configuration. This is more or less borrowed from
# the Armadillo build_tarballs.jl script:
#   https://github.com/JuliaPackaging/Yggdrasil/blob/48d7a89b4aa46b1a8c91269bb138a660f4ee4ece/A/armadillo/build_tarballs.jl#L23-L52
#
# We need to manually set up OpenBLAS because FindOpenBLAS.cmake does not work with BB:
if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64* ]]; then
    OPENBLAS="${libdir}/libopenblas64_.${dlext}"
else
    OPENBLAS="${libdir}/libopenblas.${dlext}"
fi

# Compile libhelfem as a static library
cd ${WORKSPACE}/srcdir/HelFEM/
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DHELFEM_BINARIES=OFF \
    -DHELFEM_FIND_DEPS=ON \
    -DUSE_OPENMP=OFF \
    -B build/ -S .
make -C build/ -j${nproc} helfem
make -C build/ install
# Copy the HelFEM license
install_license LICENSE

# Compile the CxxWrap wrapper as a shared library
cd ${WORKSPACE}/srcdir/HelFEM/julia
cmake \
    -DBLAS_LIBRARIES=${OPENBLAS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix} \
    -B build/ -S .
make -C build/ -j${nproc}
make -C build/ install
"""

# These are the platforms the libcxxwrap_julia_jll is built on.
include("../../L/libjulia/common.jl")
platforms = libjulia_platforms(julia_version)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libhelfem-cxxwrap", :libhelfem),
]

dependencies = [
    BuildDependency(PackageSpec(name="libjulia_jll", version=julia_version)),
    Dependency("libcxxwrap_julia_jll"),
    Dependency(PackageSpec(name = "armadillo_jll", compat = "9.850.1")),
    Dependency(PackageSpec(name = "GSL_jll", compat = "2.6.0")),
    Dependency(PackageSpec(name = "OpenBLAS_jll", compat = "0.3.9")),
]

# preferred_gcc_version = v"8" is a requirement from libcxxwrap_julia_jll
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"8",
               julia_compat = "$(julia_version.major).$(julia_version.minor)")
