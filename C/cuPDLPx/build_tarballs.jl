using Pkg, BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuPDLPx"
version = v"0.2.5"


sources = [
    GitSource(
        "https://github.com/MIT-Lu-Lab/cuPDLPx.git",
        "5d69ab0a311918371423c58f1d3f221e5237a225",
    ),
]

script = raw"""
apk del cmake

cd ${WORKSPACE}/srcdir/cuPDLPx
install_license LICENSE

export CUDA_HOME="${prefix}/cuda"
export PATH=${PATH}:${CUDA_HOME}/bin

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

cmake -B build -S . \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_CXX_STANDARD_REQUIRED=ON \
    -DCMAKE_CUDA_STANDARD=20 \
    -DCMAKE_CUDA_STANDARD_REQUIRED=ON \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME \
    -DCUPDLPX_BUILD_SHARED_LIB=ON \
    -DCUPDLPX_BUILD_STATIC_LIB=OFF \
    -DCUPDLPX_BUILD_CLI=OFF \
    -DCUPDLPX_BUILD_TESTS=OFF \
    -DCUPDLPX_BUILD_PYTHON=OFF

cmake --build build --config Release -j${nproc}

cmake --install build
"""

products = [
    LibraryProduct("libcupdlpx", :libcupdlpx),
    # ExecutableProduct("cupdlpx", :cupdlpx),
]

platforms = CUDA.supported_platforms(; min_version = v"12.4", max_version = v"13.1.999")
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
        preferred_gcc_version = v"9",
        julia_compat = "1.10",
        augment_platform_block = CUDA.augment,
    )
end
