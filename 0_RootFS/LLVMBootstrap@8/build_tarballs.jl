name = "LLVMBootstrap"
version = v"8.0.1"

# Include everything common between our LLVM versions (That's a lot)
include("../llvm_common.jl")

# Build the tarballs, then upload to Yggdrasil releases
build_info = build_tarballs(ARGS, name, version, sources, script, [host_platform], products, dependencies; skip_audit=true)
upload_and_insert_shards("JuliaPackaging/Yggdrasil", name, version, build_info)
