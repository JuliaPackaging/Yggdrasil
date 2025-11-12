using Pkg, BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuPDLPx"
version = v"0.1.2"


sources = [
    GitSource(
        "https://github.com/MIT-Lu-Lab/cuPDLPx.git",
        "e4026316e3d23ddccd3a3ba7ba41faee40797c05",
    ),
]

script = raw"""
apk del cmake

cd ${WORKSPACE}/srcdir/cuPDLPx
install_license LICENSE

export CUDA_HOME="${prefix}/cuda"
export PATH=${PATH}:${CUDA_HOME}/bin

cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME \
    -DCMAKE_CUDA_RUNTIME_LIBRARY=Static \

cmake --build build --config Release -j${nproc}

cmake --install build
"""

products = [
    LibraryProduct("libcupdlpx", :libcupdlpx),
    # ExecutableProduct("cupdlpx", :cupdlpx),
]

platforms = CUDA.supported_platforms(; min_version = v"12.4", max_version = v"12.999")
filter!(p -> arch(p) == "x86_64", platforms)

for platform in platforms
    if !should_build_platform(triplet(platform))
        continue
    end
    dependencies = [
        HostBuildDependency(PackageSpec(; name="CMake_jll")),
        Dependency("Zlib_jll"),
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        CUDA.required_dependencies(platform, static_sdk=true)...,
    ]
    build_tarballs(
        ARGS,
        name,
        version,
        sources, 
        script,
        [platform],
        products,
        dependencies;
        preferred_gcc_version = v"8",
        julia_compat = "1.10",
        augment_platform_block = CUDA.augment,
    )
end
