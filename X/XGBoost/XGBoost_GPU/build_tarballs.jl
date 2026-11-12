include("../common.jl")
name = "XGBoost_GPU"
version = v"2.1.5"

include(normpath(joinpath(YGGDRASIL_DIR, "..", "platforms", "cuda.jl")))

# Collection of sources required to build XGBoost
sources = get_sources()

# Bash recipe for building across all platforms
script = raw"""
# remove default cmake to use newer version from build dependency
apk del cmake

cd ${WORKSPACE}/srcdir/xgboost
git submodule update --init

mkdir build && cd build

# nvcc writes to /tmp, which is a small tmpfs in our sandbox.
# make it use the workspace instead
export TMPDIR=${WORKSPACE}/tmpdir
mkdir ${TMPDIR}

# Ensure CUDA is on the path
export CUDA_HOME=${WORKSPACE}/destdir/cuda;
export PATH=$PATH:$CUDA_HOME/bin
export CUDACXX=$CUDA_HOME/bin/nvcc

# nvcc thinks the libraries are located inside lib64, but the SDK actually has them in lib
ln -s ${CUDA_HOME}/lib ${CUDA_HOME}/lib64

cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
        -DCUDA_TOOLKIT_ROOT_DIR=${prefix}/cuda \
        -DUSE_CUDA=ON \
        -DBUILD_WITH_CUDA_CUB=ON
make -j${nproc}
cd ..
""" * install_script

augment_platform_block = CUDA.augment

# The products that we will ensure are always built
products = get_products()

# XGBoost v2.1 only has CUDA support for linux builds and doesn't support CUDA v13
# note also builds don't work for CUDA v12.5 and v12.6 due to a bug in CCCL (the patch fix for this is 
# not available in the shipped CUDA SDK)
# see the following issues: https://github.com/dmlc/xgboost/issues/10555, https://github.com/dmlc/xgboost/issues/11640
platforms = expand_cxxstring_abis(
    filter!(p -> all([
            arch(p) == "x86_64", 
            os(p) == "linux",
            p.tags["cuda"] ∉ ["12.5", "12.6"]
        ]),
        CUDA.supported_platforms(; min_version = v"11.8", max_version = v"12.9.1")
    )
)


for platform ∈ platforms
    
    # For platforms we can't create cuda builds on, we want to avoid adding cuda=none
    # https://github.com/JuliaPackaging/Yggdrasil/issues/6911#issuecomment-1599350319
    should_build_platform(triplet(platform)) || continue

    dependencies = get_dependencies(platform)

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)
    
    build_tarballs(ARGS, name, version, sources,  script, [platform], products, [dependencies; cuda_deps];
                    preferred_gcc_version=v"9",
                    julia_compat="1.6",
                    augment_platform_block)

end