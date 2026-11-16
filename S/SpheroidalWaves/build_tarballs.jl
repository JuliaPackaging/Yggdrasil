using BinaryBuilder

name = "SpheroidalWaves"
version = v"0.7.0"

sources = [
    GitSource("https://github.com/brandynlucca/SpheroidalWaves.jl.git",
    "f8e037fadd18e77a34ad81583180e2d1253d99aa"; tag="v$(version)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/SpheroidalWaves*
cmake -S . -B build-binarybuilder \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DSWF_BUILD_QUAD=ON \
    -DSWF_BUILD_MPFR=ON \
    -DSWF_BUILD_TESTS=OFF
cmake --build build-binarybuilder --parallel 1
cmake --install build-binarybuilder
install_license LICENSE
"""

platforms = supported_platforms()

# The quad backend requires REAL(16)/__float128, unavailable on 32-bit ARM and PowerPC64LE
filter!(p -> !(arch(p) in ("armv6l", "armv7l", "powerpc64le")), platforms)

platforms = expand_gfortran_versions(platforms)

products = [
    LibraryProduct(["libspheroidal_batch_double", "spheroidal_batch_double"], :libspheroidal_batch_double),
    LibraryProduct(["libspheroidal_batch_quad", "spheroidal_batch_quad"], :libspheroidal_batch_quad),
    LibraryProduct(["libspheroidal_batch_mpfr", "spheroidal_batch_mpfr"], :libspheroidal_batch_mpfr)
]

dependencies = [Dependency("CompilerSupportLibraries_jll"), Dependency("MPFR_jll"),
    Dependency("MPC_jll"), Dependency("GMP_jll")]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"12", julia_compat = "1.10")

# Build trigger: 1
