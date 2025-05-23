# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "UCX"
version = v"1.18.1"

MIN_CUDA_VERSION = v"11.8"
MAX_CUDA_VERSION = v"12.9.999"
ROCM_VERSION = v"5.4.4"


# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openucx/ucx.git",
                  "d9aa5650d4cbcbb00d61af980614dbe9dd27a1f2"),
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucx*

# Apply all our patches
if [ -d $WORKSPACE/srcdir/patches ]; then
for f in $WORKSPACE/srcdir/patches/*.patch; do
    echo "Applying patch ${f}"
    atomic_patch -p1 ${f}
done
fi

./autogen.sh
update_configure_scripts --reconf

FLAGS=()
FLAGS+=(--prefix=${prefix})
FLAGS+=(--build=${MACHTYPE})
FLAGS+=(--host=${target})
FLAGS+=(--disable-debug)
FLAGS+=(--disable-assertions)
FLAGS+=(--disable-params-check)
FLAGS+=(--disable-static)
FLAGS+=(--disable-profiling)
FLAGS+=(--enable-shared)
FLAGS+=(--enable-mt)
FLAGS+=(--enable-frame-pointer)
FLAGS+=(--enable-cma)
FLAGS+=(--with-rdmacm=${prefix})
FLAGS+=(--with-cuda=${prefix}/cuda)

if [[ "${target}" == *x86_64* ]]; then
    FLAGS+=(--with-rocm=${prefix})
fi

./configure ${FLAGS[@]}

# For a bug in `src/uct/sm/cma/Makefile` that I did't have the time to look
# into, we have to build with `V=1`
make -j${nproc} V=1
make install

install_license LICENSE

"""

platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)

# The products that we will ensure are always built
products = [
    LibraryProduct("libuct", :libuct),
    LibraryProduct("libucm", :libucm),
    LibraryProduct("libucp", :libucp),
    LibraryProduct("libucs", :libucs),
    ExecutableProduct("ucx_info", :ucx_info),
    ExecutableProduct("ucx_perftest", :ucx_perftest),
    ExecutableProduct("ucx_read_profile", :ucx_read_profile),
]

# Dependencies that must be installed before this package can be built
# - librdmacm -> provided through rdma-core, need glibc 2.15
# - libibcm   -> legacy libibverbs
# - knem  -> kernel module
# - xpmem -> kernel module
# - CUDA -> Figure out how version dependent we are
#   - gdrcopy -> kernel module
# - ROCM -> TODO

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency(PackageSpec(name="NUMA_jll", uuid="7f51dc2b-bb24-59f8-b771-bb1490e4195d")),
    Dependency(PackageSpec(name="rdma_core_jll", uuid="69dc3629-5c98-505f-8bcd-225213cebe70")),
    BuildDependency(PackageSpec(name="hsa_rocr_jll", version=ROCM_VERSION))
]


for platform in platforms

    should_build_platform(triplet(platform)) || continue

    cuda_deps = CUDA.required_dependencies(platform, static_sdk=true)

    build_tarballs(ARGS, name, version, sources, script, [platform],
                    products, [dependencies; cuda_deps];
                    julia_compat = "1.10", preferred_gcc_version = v"5",
                    augment_platform_block=CUDA.augment, 
                )
end
