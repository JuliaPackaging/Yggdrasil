using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))
include("../common.jl")

name = "LLD_unified"
version = v"0.1"
llvm_full_versions = [
    v"15.0.7+10",
    v"16.0.6+4",
    v"17.0.6+5",
    v"18.1.7+3",
    v"19.1.1+0",
]

augment_platform_block = """
    using Base.BinaryPlatforms

    $(LLVM.augment)

    function augment_platform!(platform::Platform)
        augment_llvm!(platform)
    end"""

# determine exactly which tarballs we should build
builds = []
for llvm_assertions in (false, true), llvm_full_version in llvm_full_versions
    llvm_full_version >= v"15" || continue
    libllvm_version = llvm_full_version
    _, _, sources, script, platforms, products, dependencies =
        configure_extraction(ARGS, llvm_full_version, "LLD", libllvm_version;
                             assert=llvm_assertions, augmentation=true,
                             dont_dlopen=false)
    # ignore the output version, as we want a unified JLL
    dependencies = map(dependencies) do dep
        # ignore the version of any LLVM dependency, as we'll automatically load
        # an appropriate version of LLD via platform augmentations
        # TODO: make this an argument to `configure_extraction`?
        if isa(dep, Dependency) && contains(dep.pkg.name, "LLVM")
            Dependency(dep.pkg.name; dep.platforms)
        else
            dep
        end
    end
    push!(builds, [name, version, sources, script, platforms, products, dependencies])
end

# don't allow `build_tarballs` to override platform selection based on ARGS.
# we handle that ourselves by calling `should_build_platform`
non_platform_ARGS = filter(arg -> startswith(arg, "--"), ARGS)

# `--register` should only be passed to the latest `build_tarballs` invocation
non_reg_ARGS = filter(arg -> arg != "--register", non_platform_ARGS)

for (i, build) in enumerate(builds)
    build_tarballs(i == lastindex(builds) ? non_platform_ARGS : non_reg_ARGS,
                   build...;
                   skip_audit=true, dont_dlopen=true, julia_compat="1.10",
                   augment_platform_block)
end
