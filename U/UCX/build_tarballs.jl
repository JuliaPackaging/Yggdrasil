# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "UCX"
version = v"1.20.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openucx/ucx.git",
                  "4b7a6ca8410f9cea0e15857233ecfeefdd863dde"),
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucx*

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

"""

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"13.0.999" 

cpu_platforms = [Platform("x86_64", "linux"; libc="glibc"), Platform("aarch64", "linux"; libc="glibc")]

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)
filter!(p -> arch(p) == "x86_64", cuda_platforms) # ARM+CUDA+UCX should work, but not gonna do that today

all_platforms = [cpu_platforms; cuda_platforms]

for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end

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
    Dependency("NUMA_jll"),
    Dependency("rdma_core_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]


for platform in all_platforms

    should_build_platform(triplet(platform)) || continue

    platform_deps = BinaryBuilder.AbstractDependency[dependencies...]
    platform_script = deepcopy(script)

    if haskey(platform, "cuda") && platform["cuda"] != "none" 
        append!(platform_deps, CUDA.required_dependencies(platform))

        platform_script *= "\n"
        platform_script *= raw"""
            FLAGS+=(--with-cuda=${prefix}/cuda)
            export CUDA_HOME=${prefix}/cuda;
            export PATH=$PATH:$CUDA_HOME/bin
            export CUDACXX=$CUDA_HOME/bin/nvcc
            export CUDA_LIB=${CUDA_HOME}/lib
        """

    end

    platform_script *= "\n"
    platform_script *= raw"""
        ./configure ${FLAGS[@]}

        # For a bug in `src/uct/sm/cma/Makefile` that I did't have the time to look
        # into, we have to build with `V=1`
        make -j${nproc} V=1
        make install

        install_license LICENSE
        """

    build_tarballs(
        ARGS, name, version, sources, 
        platform_script, [platform], products, platform_deps;
        julia_compat = "1.10", 
        preferred_gcc_version = v"7",
        lazy_artifacts = true,
        augment_platform_block = CUDA.augment
    )

end
