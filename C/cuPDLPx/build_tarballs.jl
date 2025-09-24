using Pkg, BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "cuPDLPx"
version = v"0.1.0"

sources = [
    GitSource(
        "https://github.com/ZedongPeng/cuPDLPx.git",
        "6c9c99472023aae268c2dae690eadd1a3d37733c",
    ),
]

script = raw"""
cd ${WORKSPACE}/srcdir/cuPDLPx
export CUDA_HOME="${prefix}/cuda"
export PATH=${PATH}:${CUDA_HOME}/bin
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64
make install PREFIX=$prefix
"""

products = [
    LibraryProduct("libcupdlpx", :libcupdlpx),
]

platforms = CUDA.supported_platforms(; min_version = v"12.4")
filter!(p -> arch(p) == "x86_64", platforms)

for platform in platforms
    if !should_build_platform(triplet(platform))
        continue
    end
    dependencies = [
        Dependency("Zlib_jll"),
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
        CUDA.required_dependencies(platform; static_sdk = true)...,
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
