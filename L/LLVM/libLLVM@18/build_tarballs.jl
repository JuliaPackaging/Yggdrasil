name = "libLLVM"
version = v"18.1.7+5"

using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
# Include common tools.
include("../common.jl")

augment_platform_block = """
    using Base.BinaryPlatforms
    $(LLVM.augment)
    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for llvm_assertions in (false, true)
    # Dependencies that must be installed before this package can be built!
    llvm_name, uuid = llvm_assertions ? ("LLVM_full_assert_jll", "6ec703ca-3f29-566b-9bb1-b5c9e844abaf") : ("LLVM_full_jll", "a3ccf953-465e-511d-b87f-60a6490c289d")
    dependencies = [
        BuildDependency(PackageSpec(;name=llvm_name, uuid, version))
    ]
    push!(builds, configure_extraction(ARGS, version, name; assert=llvm_assertions, augmentation=true))
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   build...;
                   skip_audit=true, julia_compat="1.12",
                   augment_platform_block)
end
