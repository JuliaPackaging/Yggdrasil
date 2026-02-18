using BinaryBuilder
using BinaryBuilderBase

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLASConsistentFPCSR"
version = v"0.3.31"

sources = openblas_sources(version)
script = openblas_script(; aarch64_ilp64=true, num_64bit_threads=512, bfloat16=true, consistent_fpcsr=true)
platforms = expand_gfortran_versions(supported_platforms(; exclude=p -> !(arch(p) in ("x86_64", "aarch64"))))
products = openblas_products()
preferred_gcc_version = v"11"
preferred_llvm_version = v"18.1.7"
dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

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

# Build trigger: 0
