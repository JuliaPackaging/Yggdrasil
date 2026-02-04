using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.13.0"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "1bce6d5c801398dab6d2e6f98ac8935f3d4eec9c",
    ),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable riscv, powerpc, and freebsd for now
platforms = filter!(p -> arch(p) != "riscv64", platforms)
platforms = filter!(p -> arch(p) != "powerpc64le", platforms)
platforms = filter!(p -> !(os(p) == "freebsd" && arch(p) == "aarch64"), platforms)

script = raw"""
cd $WORKSPACE/srcdir/HiGHS

# Remove system CMake to use the jll version
apk del cmake

mkdir -p build
cd build

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DZLIB_USE_STATIC_LIBS=${BUILD_STATIC} \
    -DHIPO=ON \
    -DBLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    ..

if [[ "${target}" == *-linux-* ]]; then
        make -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build . --config Release
    else
        cmake --build . --config Release --parallel
    fi
fi
make install

install_license ../LICENSE.txt
"""

products = [
    LibraryProduct("libhighs", :libhighs),
    ExecutableProduct("highs", :highs),
]

platforms = expand_cxxstring_abis(platforms)

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Zlib_jll"),
    # This is the version that supports Julia v1.10
    Dependency("OpenBLAS32_jll"; compat = "0.3.24"),
    HostBuildDependency(PackageSpec(; name="CMake_jll")),
]

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = v"6",
    julia_compat = "1.10",
)
