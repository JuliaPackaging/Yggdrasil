using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
include("../common.jl")

name = "Clang"
version = v"0.1"

augment_platform_block = """
    using Base.BinaryPlatforms

    $(LLVM.augment)

    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i,llvm_version) in enumerate(keys(llvm_tags))
    llvm_version >= v"11" || continue
    build_tarballs(i == length(llvm_tags) ? non_platform_ARGS : non_reg_ARGS,
                   "Clang_unified", version,
                   configure_unified_extraction(ARGS, llvm_version, name;
                                                experimental_platforms=true)...;
                   skip_audit=true, julia_compat="1.6",
                   augment_platform_block, lazy_artifacts=true)
end
