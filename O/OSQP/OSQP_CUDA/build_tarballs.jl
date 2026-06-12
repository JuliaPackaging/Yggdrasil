# To ensure a build, it isn't sufficient to modify osqp_common.jl.
# You also need to update a line in this file:
#     Last updated: 2025-05-29

include("../osqp_common.jl")

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))

# Generate the script to build the library with double precision
dscript = build_script(algebra  = "cuda",
                       suffix   = "cuda_double",
                       usefloat = false,
                       builddir = "build-double")

# Generate the script to build the library with single precision
sscript = build_script(algebra  = "cuda",
                       suffix   = "cuda_single",
                       usefloat = true,
                       builddir = "build-single")

script = raw"""
         ## CUDA setup
         # nvcc writes to /tmp, which is a small tmpfs in our sandbox.
         # make it use the workspace instead
         export TMPDIR=${WORKSPACE}/tmpdir
         mkdir ${TMPDIR}

         export CUDA_HOME=${WORKSPACE}/destdir/cuda;
         export PATH=$PATH:$CUDA_HOME/bin
         export CUDACXX=$CUDA_HOME/bin/nvcc

         ln -s ${WORKSPACE}/destdir/cuda/lib ${WORKSPACE}/destdir/cuda/lib64
         """ *
         init_env_script() * dscript * sscript

# The products that we will ensure are always built
products = [
    # Codegen is not part of the Cuda version of the library
    LibraryProduct("libosqp_cuda_single", :osqp_cuda_single)
    LibraryProduct("libosqp_cuda_double", :osqp_cuda_double)
]

# Don't build with CUDA 13 yet
platforms = CUDA.supported_platforms(max_version = v"12.999")
filter!(p -> arch(p) == "x86_64", platforms)
platforms = expand_cxxstring_abis(platforms)

for platform in platforms
    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    # OSQP uses CUB, which requires C++14 and GCC 5 (minimum), so for ease of use, just use g++ 9,
    # which has C++14 by default.
    build_tarballs(ARGS, "OSQP_CUDA", version, sources,  script, [platform], products, [common_deps..., cuda_deps...];
                   julia_compat="1.6", augment_platform_block=CUDA.augment, preferred_gcc_version=v"9")
end
