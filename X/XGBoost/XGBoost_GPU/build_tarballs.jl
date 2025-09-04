using BinaryBuilder
using BinaryBuilderBase
using Pkg

name = "XGBoost_GPU"
version = v"2.1.4"

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Collection of sources required to build XGBoost
sources = [
    GitSource("https://github.com/dmlc/xgboost.git","62e7923619352c4079b24303b367134486b1c84f"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
    "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

mkdir build && cd build

# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

export CUDA_HOME=${WORKSPACE}/destdir/cuda
export PATH=$PATH:$CUDA_HOME/bin
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCUDA_TOOLKIT_ROOT_DIR=${WORKSPACE}/destdir/cuda \
        -DUSE_CUDA=ON \
        -DBUILD_WITH_CUDA_CUB=ON
make -j${nproc}

# Manual installation, to avoid installing dmlc
cd ..
for header in include/xgboost/*.h; do
    install -Dv "${header}" "${includedir}/xgboost/$(basename ${header})"
done

install -Dvm 0755 lib/libxgboost.${dlext} ${libdir}/libxgboost.${dlext}

install_license LICENSE
"""

augment_platform_block = CUDA.augment

versions_to_build = [
    v"11.4",
    v"12.2",
    v"12.8",
]

# The products that we will ensure are always built
products = [
    LibraryProduct(["libxgboost", "xgboost"], :libxgboost),
]

platforms = expand_cxxstring_abis(supported_platforms())[3:4]

for cuda_version in versions_to_build, platform in platforms

    cuda_platform = (os(platform) == "linux") && (arch(platform) in ["x86_64"])
    if !cuda_platform
        continue
    end
    
    # For platforms we can't create cuda builds on, we want to avoid adding cuda=none
    # https://github.com/JuliaPackaging/Yggdrasil/issues/6911#issuecomment-1599350319
    augmented_platform = Platform(arch(platform), os(platform);
        cxxstring_abi = cxxstring_abi(platform),
        cuda=CUDA.platform(cuda_version)
    )
    should_build_platform(triplet(augmented_platform)) || continue

    dependencies = AbstractDependency[
        # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
        # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
        Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"); 
            platforms=filter(!Sys.isbsd, [augmented_platform])),
        Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e"); 
            platforms=filter(Sys.isbsd, [augmented_platform])),
        BuildDependency(PackageSpec(name="CUDA_full_jll", version=CUDA.full_version(cuda_version))),
        RuntimeDependency(PackageSpec(name="CUDA_Runtime_jll")),
    ]

    build_tarballs(ARGS, name, version, sources,  script, [augmented_platform], products, dependencies;
                    preferred_gcc_version=v"9",
                    julia_compat="1.6",
                    augment_platform_block)

end