# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

include(joinpath(@__DIR__, "..", "..", "fancy_toys.jl"))
include(joinpath(@__DIR__, "..", "..", "platforms", "cuda.jl"))

name = "Gloo"
version = v"0.0.20210521"

sources = [
    GitSource("https://github.com/facebookincubator/gloo.git", "c22a5cfba94edf8ea4f53a174d38aa0c629d070f"),
    DirectorySource("./bundled"),
]

script = raw"""
cd $WORKSPACE/srcdir/gloo

atomic_patch -p1 ../patches/mingw32.patch
atomic_patch -p1 ../patches/mingw-lowercase-include.patch
atomic_patch -p1 ../patches/mingw32-link-with-ws2_32.patch
atomic_patch -p1 ../patches/musl-caddr.patch

cmake_extra_args=()

if [[ $target != *w64-mingw32* ]]; then
    cmake_extra_args+=(-DUSE_LIBUV=ON)
fi

cuda_version=${bb_full_target##*-cuda+}
if [[ $bb_full_target == *cuda* ]] && [[ $cuda_version != none ]]; then
    export CUDA_PATH="$prefix/cuda"
    mkdir $WORKSPACE/tmpdir
    export TMPDIR=$WORKSPACE/tmpdir
    cmake_extra_args+=(
        -DUSE_CUDA=ON
        -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_PATH
    )
fi

cmake \
    -B build \
    -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    ${cmake_extra_args[@]}
cmake --build build --parallel $nproc
cmake --install build
"""

platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms) # Gloo can only be built on 64-bit systems

let cuda_platforms = CUDA.supported_platforms(min_version=v"10.2", max_version=v"11")
    push!(cuda_platforms, Platform("x86_64", "Linux"; cuda = "11.3"))

     # Tag non-CUDA platforms matching CUDA platforms with cuda="none"
    for platform in platforms
        if CUDA.is_supported(platform) && arch(platform) != "aarch64"
            platform["cuda"] = "none"
        end
    end
    append!(platforms, cuda_platforms)
end

platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libgloo", :libgloo),
]

dependencies = [
    BuildDependency("LibUV_jll"),
]

builds = []
for platform in platforms
    should_build_platform(platform) || continue
    additional_deps = BinaryBuilder.AbstractDependency[]
    if haskey(platform, "cuda") && platform["cuda"] != "none"
        if platform["cuda"] == "11.3"
            additional_deps = BinaryBuilder.AbstractDependency[
                BuildDependency(PackageSpec("CUDA_full_jll", v"11.3.1")),
                Dependency("CUDA_Runtime_jll", v"0.7.0"), # Using v"0.7.0" to get support for cuda = "11.3" - using Dependency rather than RuntimeDependency to be sure to pass audit
            ]
        else
            additional_deps = CUDA.required_dependencies(platform, static_sdk = true)
        end
    end
    push!(builds, (; platforms=[platform], dependencies=[dependencies; additional_deps]))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, sources, script,
                   build.platforms, products, build.dependencies;
        preferred_gcc_version = v"5",
        julia_compat = "1.6",
        augment_platform_block = CUDA.augment,
    )
end
