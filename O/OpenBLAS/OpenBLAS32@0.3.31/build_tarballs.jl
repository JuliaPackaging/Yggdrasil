using BinaryBuilder
using BinaryBuilderBase

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS32"
version = v"0.3.31"

sources = openblas_sources(version)
script = openblas_script(openblas32=true, bfloat16=true, float16=true)
platforms = openblas_platforms(; version)
products = openblas_products()
preferred_gcc_version = v"12"
preferred_llvm_version = v"18.1.7"
dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

# Do we build all platforms, or those specified as arguments?
platform_args = filter(arg -> !startswith(arg, "--"), ARGS)
if !isempty(platform_args)
    @assert length(platform_args) == 1
    platforms = BinaryBuilderBase.parse_platform.(split(platform_args[1], ","))
end

riscv64_preferred_gcc_version = v"15"

# The regular options, excluding the list of platforms
option_args = filter(arg -> startswith(arg, "--"), ARGS)
non_register_option_args = filter(arg -> arg != "--register", option_args)

for (n,platform) in enumerate(platforms)
    # We register the build products only after the last build.
    args = n == length(platforms) ? option_args : non_register_option_args

    build_tarballs(args, name, version, sources, script, [platform], products, dependencies;
                   julia_compat="1.11",
                   lock_microarchitecture=false,
                   preferred_gcc_version = arch(platform) == "riscv64" ? riscv64_preferred_gcc_version : preferred_gcc_version,
                   preferred_llvm_version=preferred_llvm_version,
                   )
end

# Build trigger: 2
