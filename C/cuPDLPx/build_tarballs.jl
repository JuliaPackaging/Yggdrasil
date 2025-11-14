using Pkg, BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuPDLPx"
version = v"0.1.2"


sources = [
    GitSource(
        "https://github.com/MIT-Lu-Lab/cuPDLPx.git",
        "43c7958bf4de5056d12763081e35b7f6a1fbe0b4",
    ),
]

script = raw"""
# check if we need to use a more recent glibc
if [[ -f "$prefix/usr/include/sched.h" ]]; then
    GLIBC_ARTIFACT_DIR=$(dirname $(dirname $(dirname $(realpath $prefix/usr/include/sched.h))))
    rsync --archive ${GLIBC_ARTIFACT_DIR}/ /opt/${target}/${target}/sys-root/
fi

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
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME \

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
        BuildDependency(PackageSpec(name = "Glibc_jll")),
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
