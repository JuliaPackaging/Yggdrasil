# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.

# based on new UCX build script from: https://github.com/JuliaPackaging/Yggdrasil/pull/13039
using BinaryBuilder, Pkg


const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "cuda.jl"))
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))

name = "UCC"
version = v"1.6.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/openucx/ucc.git",
                  "87ee888b78d12d797ac8288c8214c7cb86c8bd8c"),
    ]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ucc*

./autogen.sh

FLAGS=()
FLAGS+=(--prefix=${prefix})
FLAGS+=(--build=${MACHTYPE})
FLAGS+=(--host=${target})
FLAGS+=(--with-ucx=${prefix})
FLAGS+=(--disable-debug)
FLAGS+=(--enable-shared)

"""

MIN_CUDA_VERSION = v"12.2"
MAX_CUDA_VERSION = v"13.0.999" 

# We need to wait until https://github.com/JuliaPackaging/Yggdrasil/pull/13039 is merged
# for the newer CUDA version support in UCX_jll for things to properly work

cpu_platforms = [Platform("x86_64", "linux"; libc="glibc"), Platform("aarch64", "linux"; libc="glibc")]

cuda_platforms = CUDA.supported_platforms(; min_version = MIN_CUDA_VERSION, max_version = MAX_CUDA_VERSION)
filter!(p -> arch(p) == "x86_64", cuda_platforms)

all_platforms = [cpu_platforms; cuda_platforms]

for platform in all_platforms
    if CUDA.is_supported(platform) && !haskey(platform, "cuda")
        platform["cuda"] = "none"
    end
end

products = [
    LibraryProduct("libucc", :libucc),
    ExecutableProduct("ucc_info", :ucc_info),
]

dependencies = [
    Dependency("UCX_jll"; compat="~1.20.0"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
]


for platform in all_platforms

    should_build_platform(triplet(platform)) || continue

    platform_deps = BinaryBuilder.AbstractDependency[dependencies...]
    platform_script = deepcopy(script)

    if haskey(platform, "cuda") && platform["cuda"] != "none" 
        append!(platform_deps, CUDA.required_dependencies(platform))
        push!(platform_deps, Dependency("NCCL_jll"; compat="=2.27.7")) # force NCCL without patch?

        platform_script *= "\n"
        platform_script *= raw"""
            FLAGS+=(--with-cuda=${prefix}/cuda)
            FLAGS+=(--with-nccl=${prefix})
            export CUDA_HOME=${prefix}/cuda;
            export PATH=$PATH:$CUDA_HOME/bin
            export CUDACXX=$CUDA_HOME/bin/nvcc
            export CUDA_LIB=${CUDA_HOME}/lib
        """

    end

    platform_script *= "\n"
    platform_script *= raw"""
        ./configure ${FLAGS[@]}

        make -j${nproc} V=1
        make install

        install_license LICENSE
    """

    build_tarballs(
        ARGS, name, version, sources, 
        platform_script, [platform], products, platform_deps;
        julia_compat = "1.10", 
        preferred_gcc_version = v"11",
        lazy_artifacts = true,
        augment_platform_block = CUDA.augment
    )

end
