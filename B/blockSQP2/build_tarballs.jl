using BinaryBuilder, Pkg

name = "blockSQP2"
version = v"0.1.0"
sources = [
    GitSource("https://github.com/ReWittmann/blockSQP2.git", "e92bb91a4d6c1d2b77974e17980fdc370c8b7cd1"),
]


script = raw"""
apk del cmake
cd ${WORKSPACE}/srcdir
mv blockSQP2/CMake/CMakeListsBinaryBuilderjl.cmake blockSQP2/CMakeLists.txt
cd blockSQP2

LOBSUFFIX=""

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_FIND_ROOT_PATH=$prefix \
    -DCMAKE_PREFIX_PATH=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCBLAS_SUFFIX="$LOBSUFFIX" \
    -DINCLUDE_DIR=${includedir} \
    -DMUMPS_LIBRARIES="${libdir}/libdmumps.${dlext}" \
    -DMUMPS_COMMON_LIBRARY="${libdir}/libmumps_common.${dlext}" \
    -DMUMPS_PORD_LIBRARY="${libdir}/libpord.${dlext}" \
    -DMUMPS_MPISEQ_LIBRARY="${libdir}/libmpiseq.${dlext}" \
    -S .. \
    -B .
make
make install
install_license ${WORKSPACE}/srcdir/blockSQP2/LICENSE
mkdir ${prefix}/share/licenses/blockSQP && cp ${WORKSPACE}/srcdir/blockSQP2/blockSQP2/LICENSE ${prefix}/share/licenses/blockSQP/LICENSE
mkdir ${prefix}/share/licenses/qpOASES && cp ${WORKSPACE}/srcdir/blockSQP2/blockSQP2/dep/modified_qpOASES/LICENSE ${prefix}/share/licenses/qpOASES/LICENSE
"""

platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(arch(p) == "i686"), platforms)
filter!(p -> !(libc(p) == "musl"), platforms)
filter!(p -> !(arch(p) == "riscv64"), platforms)
filter!(p -> !(os(p) == "freebsd"), platforms)
filter!(p -> !(os(p) == "macos"), platforms) # C++-20 std::jthread and std::stop_token seem to be unsupported on this platform


products = [
    LibraryProduct("libblockSQP2_jl", :libblockSQP2_jl)
]

dependencies = [
    Dependency(PackageSpec(name="MUMPS_seq_jll",
                uuid="d7ed1dd3-d0ae-5e8e-bfb4-87a502085b8d"),
                compat="500.800.200"),
    # Already pulled in by MUMPS_seq_jll:
    # Dependency(PackageSpec(name="libblastrampoline_jll", 
    #             uuid="8e850b90-86db-534c-a0d3-1478176c7d93"), 
    #             compat="5.4.0")
    # Convenience: Fetch OpenBLAS32 to obtain the correct headers, 
    #              but link libblastrampoline.
    Dependency(PackageSpec(name="OpenBLAS32_jll",
                uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"),
                compat="0.3.30"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll",
                uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    HostBuildDependency(PackageSpec(; name="CMake_jll"))
    ]


build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        julia_compat="1.9", preferred_gcc_version=v"11")
