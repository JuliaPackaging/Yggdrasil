# Include everything common between our LLVM versions (That's a lot)
include("../llvm_common_10+.jl")

# Build the tarballs, then upload to Yggdrasil releases

name = "LLVMBootstrap"
version = v"10.0.1"
sources, script, products, dependencies = llvm_build_args(;version=version) 
build_info = build_tarballs(ARGS, name, version, sources, script, [host_platform], products, dependencies; skip_audit=true)
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)

