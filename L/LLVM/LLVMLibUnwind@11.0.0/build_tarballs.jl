name = "LLVMLibUnwind"
llvm_full_version = v"11.0.0+10"

# Include common LLVM stuff
include("../common.jl")
build_tarballs(ARGS, configure_extraction(ARGS, llvm_full_version, name, llvm_full_version;
                                          experimental_platforms=true)...;
               skip_audit=true, preferred_gcc_version=v"6.1.0", julia_compat="1.6")
