using BinaryBuilder

name = "SpheroidalWaves"
version = v"0.5.0"

sources = [
    GitSource("https://github.com/brandynlucca/SpheroidalWaves.jl.git",
              "a56162cd3988479ae66650f8bbbb8b4f3b0d72a4"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/SpheroidalWaves*
cmake -S . -B build-binarybuilder \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-binarybuilder --parallel ${nproc}
cmake --install build-binarybuilder
install_license LICENSE
"""

# Set platforms (negative specifications)
# REFER: https://github.com/JuliaPackaging/Yggdrasil/blob/master/AGENTS.md#platforms
platforms = expand_gfortran_versions(supported_platforms())

products = [
    LibraryProduct(["libspheroidal_batch_double","spheroidal_batch_double"],:libspheroidal_batch_double),
    LibraryProduct(["libspheroidal_batch_quad","spheroidal_batch_quad"],:libspheroidal_batch_quad),
]

dependencies = [Dependency("CompilerSupportLibraries_jll")]

build_tarballs(ARGS,name,version,sources,script,platforms,products,dependencies;
               preferred_gcc_version=v"12",julia_compat="1.10")
