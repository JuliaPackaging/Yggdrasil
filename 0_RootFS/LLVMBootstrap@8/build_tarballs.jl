# Include everything common between our LLVM versions (That's a lot)
include("../llvm_common.jl")

# Build the tarballs, then upload to Yggdrasil releases

# Unfortunately, it looks like these are just too big for GitHub.  :(
#=
name = "LLVMBootstrapDebug"
version = v"8.0.1"
sources, script, products, dependencies = llvm_build_args(;version=version, llvm_build_type="RelWithDebInfo") 
build_info = build_tarballs(ARGS, name, version, sources, script, [host_platform], products, dependencies; skip_audit=true)
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)
=#

name = "LLVMBootstrap"
version = v"8.0.1"
sources, script, products, dependencies = llvm_build_args(;version=version) 
build_info = build_tarballs(ARGS, name, version, sources, script, [host_platform], products, dependencies; skip_audit=true)
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)

