using BinaryBuilder, Pkg

include("../../L/libjulia/common.jl")

name = "slope"
version = v"6.6.0"

sources = [
    GitSource("https://github.com/jolars/libslope.git", "2a62c4415e086f05ec6e1831546e0b6147cd332b"; tag="v$(version)"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libslope

cmake -B build \
    -DBUILD_TESTING=OFF \
    -DBUILD_JULIA_BINDINGS=ON \
    -DJlCxx_DIR=${prefix}/lib/cmake/JlCxx \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DJulia_PREFIX=${prefix}

cmake --build build --parallel ${nproc}
cmake --install build

install_license LICENSE
"""

# std::optional::value needs macOS 10.14 or newer.
sources, script = require_macos_sdk("10.14", sources, script)

filter!(>=(v"1.10"), julia_versions)
@assert libjulia_min_julia_version <= v"1.10.0"
platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libslopejll", :libslopejll),
]

dependencies = [
    BuildDependency("Eigen_jll"),
    BuildDependency(PackageSpec(; name="libjulia_jll", version="1.11.6")),
    # Use the build target's stdlib version for audit, with a runtime bound that admits Julia 1.10.
    BuildDependency("CompilerSupportLibraries_jll"; platforms=filter(!Sys.isbsd, platforms)),
    RuntimeDependency("CompilerSupportLibraries_jll"; compat="1.0.5", platforms=filter(!Sys.isbsd, platforms)),
    # The Clang OpenMP runtime must support __kmpc_dispatch_deinit.
    Dependency("LLVMOpenMP_jll"; compat="19.1.7 - 23", platforms=filter(Sys.isbsd, platforms)),
    # This release matches the libjulia headers for the Julia 1.14 and 1.15 variants.
    Dependency("libcxxwrap_julia_jll"; compat="0.14.14"),
]

build_tarballs(
    ARGS, name, version, sources, script, platforms, products, dependencies;
    preferred_gcc_version = v"11", julia_compat = libjulia_julia_compat(julia_versions)
)
