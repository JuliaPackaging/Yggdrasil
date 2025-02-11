name = "LLD"
llvm_full_version = v"18.1.7+3"
libllvm_version = v"18.1.7+3"

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
    push!(builds, configure_extraction(ARGS, llvm_full_version, name, libllvm_version; assert=llvm_assertions, augmentation=true))
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

# bump
