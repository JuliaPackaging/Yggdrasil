using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "rocm.jl"))

name = "rocm_sdk_core"
build_version = "7.11.0a20251130"
version = v"7.0.01120251130"

augment_platform_block = read(joinpath(@__DIR__, "platform_augmentation.jl"), String)

script = raw"""
cd ${WORKSPACE}/srcdir

unzip rocm_sdk_core-*.whl

# Copy the rocm_sysdeps folder
cp -rv _rocm_sdk_core/* ${prefix}/

install_license LICENSE.md
"""

products = [
    ExecutableProduct("ld.lld", :lld, "lib/llvm/bin"),
    LibraryProduct("libamdhip64", :libhip),
    FileProduct("lib/llvm/amdgcn/bitcode", :amdgcn_bitcode_dir)
]

dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    RuntimeDependency(PackageSpec(name="HSARuntime_jll", uuid="0a197bc1-b33e-53f1-a9ca-cd02b99357ac"); compat = "7")
]


# determine exactly which tarballs we should build
builds = []
for augmented_platform in ROCm.supported_platforms()
    should_build_platform(triplet(augmented_platform)) || continue

    p = augmented_platform["rocm_platform"]
    sha256sum, build = Dict(
        "gfx101x_dgpu" => ("4a1903f4afece374b008d376825a81b9d0d5901844c78db0dce82c17c0c66f8f", build_version),
        "gfx103x_dgpu" => ("dd4e9eceb3bc93b4f235e27d2572bedae470e32f03609487129fba14f6d512b2", build_version),
        "gfx110x_all"  => ("45327fb6874797c104275617541e6cce9b706159a962f17b410e06d9c4f66008", build_version),
        #"gfx110x_dgpu" => ("b0d27556dd07d30345624eb487ca2c7cf40060ec5f94ba6e3d788c2fead4b345", build_version),
        "gfx1150"      => ("01250b8baa92d45f0af2a32456db8e2d6d42f575afb781ef1b8fee47fe644ed2", build_version),
        "gfx1151"      => ("565b7e96e04b3f0cdd743eef5e498f697ee407c70c9a0b3702f10d3d0dcb6fc5", build_version),
        "gfx120x_all"  => ("bbeb58b80951aa0ba4c5df8ce49fc6a493012ecc49910574175fd84c948b1eb2", build_version),
        "gfx90x_dcgpu" => ("1a1ae75beabba18d5a7d94942f128801ba2448a0e4cdc74da5d9c4b26789bdbe", build_version),
        "gfx94x_dcgpu" => ("f18fda3295a8e6aa54f2d04b7dcb4631c0c7a2aac57fc774fbacf32f6071bbe0", build_version),
        "gfx950_dcgpu" => ("ff4aade1cafb8359fd6c2b39fa691f68f14bdf06557e2e5d3c61ef8bea2190e8", "7.11.0a20251129"),
    )[p]
    p = replace(p, "x_" => "X-", "_" => "-")
    sources = [
        FileSource("https://rocm.nightlies.amd.com/v2/$p/rocm_sdk_core-$build-py3-none-linux_x86_64.whl",
                   sha256sum),
        FileSource("https://raw.githubusercontent.com/ROCm/rocm-systems/fd61b0f5073a6c4c3b6693532d3cfb8972b1951f/projects/hip/LICENSE.md",
                   "b185aaa652b0bf066c37a0d6314ce4bf4521e4a3c9bf46edd2f6a777ac522223"),
    ]

    push!(builds,
        (; platforms=[augmented_platform], sources)
    )
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   name, version, build.sources, script,
                   build.platforms, products, dependencies;
                   skip_audit = true, julia_compat="1.6", lazy_artifacts=true, augment_platform_block)
end
