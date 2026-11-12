using BinaryBuilder

name = "SpheroidalWaves"
version = v"0.6.0"

sources = [
    GitSource("https://github.com/brandynlucca/SpheroidalWaves.jl.git",
    "97999e669abaa20089bfabd1a15b82cd004164f4"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/SpheroidalWaves*
cmake -S . -B build-binarybuilder \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSWF_BUILD_TESTS=OFF
cmake --build build-binarybuilder --parallel ${nproc}
cmake --install build-binarybuilder
install_license LICENSE
"""

platforms = supported_platforms()

# gfortran has no REAL(16)/__float128 (quadmath) support on 32-bit ARM or
# PowerPC64LE, so `selected_real_kind(33)` (deps/prolate_swf_quad.f90:33)
# resolves to an invalid kind and the quad-precision sources fail to compile.
filter!(p -> !(arch(p) in ("armv6l", "armv7l", "powerpc64le")), platforms)

platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct(["libspheroidal_batch_double", "spheroidal_batch_double"], :libspheroidal_batch_double),
    LibraryProduct(["libspheroidal_batch_quad", "spheroidal_batch_quad"], :libspheroidal_batch_quad)
]

dependencies = [Dependency("CompilerSupportLibraries_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"12", julia_compat = "1.10")
