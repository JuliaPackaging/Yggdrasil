using BinaryBuilder, Pkg

name = "HiGHS"

version = v"1.15.1"

sources = [
    GitSource(
        "https://github.com/ERGO-Code/HiGHS.git",
        "04024d701f79feb8e2f18bc3df0dffc04ef05088",
    ),
    DirectorySource("./bundled"),
]

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable riscv and powerpc for now
platforms = filter!(p -> arch(p) != "riscv64", platforms)
platforms = filter!(p -> arch(p) != "powerpc64le", platforms)

script = raw"""
cd $WORKSPACE/srcdir/HiGHS

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix-cli11.patch

# Remove system CMake to use the jll version
apk del cmake

rm -rf build
mkdir build

if [[ "${target}" == *-mingw* ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi

cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DHIPO=ON \
    -DBUILD_SHARED_EXTRAS_LIB=OFF \
    -DBLA_VENDOR=blastrampoline \
    -DBLAS_LIBRARIES=\"${LBT}\"

if [[ "${target}" == *-linux-* ]]; then
    make -C build -j ${nproc}
else
    if [[ "${target}" == *-mingw* ]]; then
        cmake --build build --config Release
    else
        cmake --build build --config Release --parallel
    fi
fi
cmake --install build

install_license LICENSE.txt
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
    preferred_gcc_version = v"11",
    julia_compat = "1.10",
)
