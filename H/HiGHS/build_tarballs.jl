using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.13.1"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "1d267d97c16928bb5f86fcb2cba2d20f94c8720c",
    ),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable riscv and powerpc for now
platforms = filter!(p -> arch(p) != "riscv64", platforms)
platforms = filter!(p -> arch(p) != "powerpc64le", platforms)

script = raw"""
cd $WORKSPACE/srcdir/HiGHS

# Remove system CMake to use the jll version
apk del cmake

mkdir -p build
cd build

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DHIPO=ON \
    -DBLA_VENDOR=blastrampoline \
    -DBLAS_LIBRARIES=\"${LBT}\" \
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
    Dependency("libblastrampoline_jll"),
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
