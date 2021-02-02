# Include everything common between our LLVM versions (That's a lot)
include("../llvm_common.jl")

# Build the tarballs, then upload to Yggdrasil releases

name = "LLVMBootstrap"
version = v"11.0.1"
sources, script, products, dependencies = llvm_build_args(;version=version)
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, [host_platform], products, dependencies;
                            skip_audit=true, preferred_gcc_version=v"5.1")
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info)
end

