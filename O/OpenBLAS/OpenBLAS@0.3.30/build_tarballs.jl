using BinaryBuilder
using BinaryBuilderBase

include("../common.jl")

# Collection of sources required to build OpenBLAS
name = "OpenBLAS"
version = v"0.3.30"

sources = openblas_sources(version)
script = openblas_script(; aarch64_ilp64=true, num_64bit_threads=512, bfloat16=true)
platforms = openblas_platforms(; version)
# Note: The msan build doesn't use gfortran, and we thus don't expand the gfortran versions
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))
products = openblas_products()
preferred_llvm_version = v"18.1.7"
dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=preferred_llvm_version)

# Everything below is necessary only because we need to build msan platforms with a different LLVM version.
# We can only build msan platforms with LLVM 13, but we need to build non-msan builds with LLVM 17 to get bfloat16 support.
#
# For the love of god, can someone PLEASE just build msan support for a modern LLVM?

# Do we build all platforms, or those specified as arguments?
platform_args = filter(arg -> !startswith(arg, "--"), ARGS)
if !isempty(platform_args)
    @assert length(platform_args) == 1
    platforms = BinaryBuilderBase.parse_platform.(split(platform_args[1], ","))
end

# The regular options, excluding the list of platforms
option_args = filter(arg -> startswith(arg, "--"), ARGS)

non_msan_platforms = filter(p -> sanitize(p) != "memory", platforms)
msan_platforms = filter(p -> sanitize(p) == "memory", platforms)

# Build the tarballs
if isempty(msan_platforms)
    # No special case
    build_tarballs(option_args, name, version, sources, script, non_msan_platforms, products, dependencies;
                   preferred_gcc_version=v"11", lock_microarchitecture=false,
                   julia_compat="1.11", preferred_llvm_version=preferred_llvm_version)
else
    msan_preferred_llvm_version = v"13.0.1+0"
    # Note: Only build depencencies differ between msan and non-msan builds
    msan_dependencies = openblas_dependencies(platforms; llvm_compilerrt_version=msan_preferred_llvm_version)
    if isempty(non_msan_platforms)
        # Only msan builds -- also straightforward
        build_tarballs(option_args, name, version, sources, script, msan_platforms, products, msan_dependencies;
                       preferred_gcc_version=v"11", lock_microarchitecture=false,
                       julia_compat="1.11", preferred_llvm_version=msan_preferred_llvm_version)
    else
        # We need to build both msan and non-msan platforms.
        # We register the build products only after the last build.
        non_register_option_args = filter(arg -> arg != "--register", option_args)
        build_tarballs(non_register_option_args, name, version, sources, script, non_msan_platforms, products, dependencies;
                       preferred_gcc_version=v"11", lock_microarchitecture=false,
                       julia_compat="1.11", preferred_llvm_version=preferred_llvm_version)
        build_tarballs(option_args, name, version, sources, script, msan_platforms, products, msan_dependencies;
                       preferred_gcc_version=v"11", lock_microarchitecture=false,
                       julia_compat="1.11", preferred_llvm_version=msan_preferred_llvm_version)
    end
end

# Build trigger: 2
