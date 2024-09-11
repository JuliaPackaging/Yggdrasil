# Include everything common between our LLVM versions (That's a lot)
include("../llvm_common.jl")

# Build the tarballs, then upload to Yggdrasil releases

name = "LLVMBootstrap"
version = v"18.1.7"
sources, script, products, dependencies = llvm_build_args(;version=version)
ndARGS, deploy_target = find_deploy_arg(ARGS)
# Earlier versions of GCC can cause Clang to fail with `error: unknown target CPU 'x86-64'`
# https://github.com/JuliaPackaging/BinaryBuilderBase.jl/pull/112#issuecomment-776940748
build_info = build_tarballs(ndARGS, name, version, sources, script, [host_platform], products, dependencies;
                            skip_audit=true, preferred_gcc_version=v"8")
if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info)
end
