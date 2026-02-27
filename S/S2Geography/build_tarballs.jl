using BinaryBuilder, Pkg

name = "S2Geography"
version = v"0.3.0"
sources = [
    GitSource("https://github.com/paleolimbot/s2geography.git", "04a31a89e16e59d5a827f7251c5bbd24e2f6b919"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/s2geography
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DS2GEOGRAPHY_S2_SOURCE=SYSTEM \
    -DS2GEOGRAPHY_BUILD_TESTS=OFF \
    -DS2GEOGRAPHY_BUILD_EXAMPLES=OFF \
    -DS2GEOGRAPHY_CODE_COVERAGE=OFF
cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms)
filter!(p -> !Sys.isfreebsd(p), platforms)
filter!(p -> arch(p) != "powerpc64le", platforms)
filter!(p -> arch(p) != "riscv64", platforms)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libs2geography", :libs2geography),
]

dependencies = [
    Dependency(PackageSpec(name="abseil_cpp_jll", uuid="43133aba-3931-5066-b004-a34c79b93f2e"), compat="20240116.2.0"),
    Dependency(PackageSpec(name="S2Geometry_jll", uuid="846536d6-5c10-5069-b47f-45525c463cf9"), compat="0.11.1"),
    Dependency(PackageSpec(name="nanoarrow_jll", uuid="c104a5b5-1715-5fd7-8664-28eaad6c5848")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10")
