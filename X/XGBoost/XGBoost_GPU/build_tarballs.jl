include("../common.jl")
name = "XGBoost_GPU"
version = v"2.1.4"

include(normpath(joinpath(YGGDRASIL_DIR, "..", "platforms", "cuda.jl")))

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

mkdir build && cd build

# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

export CUDA_HOME=${prefix}/cuda
export PATH=$PATH:$CUDA_HOME/bin
cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCUDA_TOOLKIT_ROOT_DIR=${prefix}/cuda \
        -DUSE_CUDA=ON \
        -DBUILD_WITH_CUDA_CUB=ON
make -j${nproc}

""" * install_script

augment_platform_block = CUDA.augment

versions_to_build = [
    v"11.8",
    v"12.0"
]

# The products that we will ensure are always built
products = get_products()

platforms = get_platforms()[3:4]

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

    dependencies = get_dependencies(augmented_platform; cuda = true, cuda_version = cuda_version)
    
    build_tarballs(ARGS, name, version, sources,  script, [augmented_platform], products, dependencies;
                    preferred_gcc_version=v"9",
                    julia_compat="1.6",
                    augment_platform_block)

end