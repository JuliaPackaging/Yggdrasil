using BinaryBuilder, Pkg
using Base.BinaryPlatforms: arch

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "C/CUDA/common.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

name = "HelloWorldCUDA"
version = v"1.0.0"

script = raw"""
cd ${WORKSPACE}/srcdir

# BinaryBuilder's x86_64 host needs x86_64 CUDA tools, paired with the target C++ compiler.
if [[ "${target}" == aarch64-* ]]; then
    export LD_LIBRARY_PATH="/usr/lib/csl-musl-x86_64:/usr/lib/csl-glibc-x86_64:${LD_LIBRARY_PATH}"
    export NVCC_PREPEND_FLAGS="-ccbin=${CXX}"
    rm -rfv ${prefix}/cuda/bin ${prefix}/cuda/nvvm/bin ${prefix}/cuda/nvvm/lib64
    cp -a cuda_nvcc-linux-x86_64-*-archive/bin ${prefix}/cuda/bin
    cp -a libnvvm-linux-x86_64-*-archive/nvvm/{bin,lib64} ${prefix}/cuda/nvvm/
fi

# nvcc searches lib64; the SDK uses lib. Vendor libraries require newer glibc symbols.
# Keep PTX (75, not 75-real) so newer GPUs can run the kernel.
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CUDA_COMPILER=${prefix}/cuda/bin/nvcc \
    -DCMAKE_CUDA_FLAGS="-L${prefix}/cuda/lib" \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--allow-shlib-undefined" \
    -DCUDAToolkit_ROOT=${prefix}/cuda \
    -DCMAKE_CUDA_ARCHITECTURES=75
cmake --build build --parallel ${nproc}
cmake --install build

# Modified SDK files would otherwise be packaged.
if [[ "${target}" == aarch64-* ]]; then
    rm -rfv ${prefix}/cuda
fi

install_license /usr/share/licenses/MIT
"""

# CUDA 13.0 artifacts also match newer CUDA 13 toolkits.
platforms = CUDA.supported_platforms(; min_version=v"13", max_version=v"13.0.999")

products = [
    LibraryProduct("libhello_cuda", :libhello_cuda),
    ExecutableProduct("hello_world_cuda", :hello_world_cuda),
]

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    sources = BinaryBuilder.AbstractSource[DirectorySource("./bundled")]
    if arch(platform) == "aarch64"
        x86_platform = deepcopy(platform)
        x86_platform["arch"] = "x86_64"
        append!(sources, get_sources("cuda", ["cuda_nvcc", "libnvvm"];
                                     version=CUDA.full_version(VersionNumber(platform["cuda"])),
                                     platform=x86_platform))
    end

    dependencies = [
        CUDA.required_dependencies(platform; static_sdk=true);
        Dependency("CompilerSupportLibraries_jll"; compat="1.0.5");
        # Prevent executables from loading a rejected forward-compatibility driver.
        RuntimeDependency("CUDA_Driver_jll"; compat="13.3.6 - 13")
    ]

    build_tarballs(ARGS, name, version, sources, script, [platform], products, dependencies;
                   julia_compat="1.10", preferred_gcc_version=v"9",
                   augment_platform_block=CUDA.augment,
                   lazy_artifacts=true, dont_dlopen=true)
end
