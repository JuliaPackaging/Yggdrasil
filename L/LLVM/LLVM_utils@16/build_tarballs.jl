name = "LLVM_utils"
llvm_full_version = v"16.0.6+6"
libllvm_version = v"16.0.6+6"

using BinaryBuilder, Pkg
using Base.BinaryPlatforms

const YGGDRASIL_DIR = "../../.."
include(joinpath(YGGDRASIL_DIR, "fancy_toys.jl"))
include(joinpath(YGGDRASIL_DIR, "platforms", "llvm.jl"))

function normalize_symbol(str)
    str = replace(str, "-"=>"_")
    if startswith(str,"ll") || str == "opt"
        return Symbol(str)
    else
        return Symbol("llvm_"*str)
    end
end

const tools_list = [
  "bugpoint",
  "count",
  "diagtool",
  "FileCheck",
  "find-all-symbols",
  "llc",
  "lli",
  "lli-child-target",
  "llvm-addr2line",
  "llvm-ar",
  "llvm-as",
  "llvm-bcanalyzer",
  "llvm-bitcode-strip",
  "llvm-c-test",
  "llvm-cat",
  "llvm-cfi-verify",
  "llvm-cov",
  "llvm-cvtres",
  "llvm-cxxdump",
  "llvm-cxxfilt",
  "llvm-cxxmap",
  "llvm-debuginfod",
  "llvm-debuginfod-find",
  "llvm-diff",
  "llvm-dis",
  "llvm-dlltool",
  "llvm-dwarfdump",
  "llvm-dwarfutil",
  "llvm-dwp",
  "llvm-extract",
  "llvm-gsymutil",
  "llvm-ifs",
  "llvm-install-name-tool",
  "llvm-jitlink",
  "llvm-jitlink-executor",
  "llvm-lib",
  "llvm-libtool-darwin",
  "llvm-link",
  "llvm-lipo",
  "llvm-lto",
  "llvm-lto2",
  "llvm-mc",
  "llvm-mca",
  "llvm-ml",
  "llvm-modextract",
  "llvm-mt",
  "llvm-nm",
  "llvm-objcopy",
  "llvm-objdump",
  "llvm-opt-report",
  "llvm-otool",
  "llvm-pdbutil",
  "llvm-PerfectShuffle",
  "llvm-profdata",
  "llvm-profgen",
  "llvm-ranlib",
  "llvm-rc",
  "llvm-readelf",
  "llvm-readobj",
  "llvm-reduce",
  "llvm-rtdyld",
  "llvm-sim",
  "llvm-size",
  "llvm-split",
  "llvm-stress",
  "llvm-strings",
  "llvm-strip",
  "llvm-symbolizer",
  "llvm-tblgen",
  "llvm-tli-checker",
  "llvm-undname",
  "llvm-windres",
  "llvm-xray",
  "modularize",
  "not",
  "obj2yaml",
  "opt",
  "pp-trace",
  "sancov",
  "sanstats",
  "split-file",
  "UnicodeNameMappingGenerator",
  "verify-uselistorder",
  "yaml-bench",
  "yaml2obj"
]
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
#!
