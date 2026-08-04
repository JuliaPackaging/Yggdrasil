# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

include("../common.jl")

name = "MPFR"
version = v"4.2.2"

sources = mpfr_sources(version)
script = mpfr_script()
platforms = mpfr_platforms()
products = mpfr_products()

preferred_llvm_version = v"17"
msan_preferred_llvm_version = v"13.0.1+0"

# Dependencies that must be installed before this package can be built
dependencies = mpfr_dependencies(platforms; llvm_compilerrt_version=msan_preferred_llvm_version)

# Everything below is necessary only because we need to build msan platforms with a different LLVM version

# Do we build all platforms, or those specified as arguments?
platform_args = filter(!startswith("--"), ARGS)
if !isempty(platform_args)
    platforms = parse_platform.(split(only(platform_args), ','))
end

# The regular options, excluding the list of platforms
option_args = filter(startswith("--"), ARGS)
non_register_option_args = filter(!=("--register"), option_args)

for (n, platform) in enumerate(platforms)
    # We register the build products only after the last build
    args = n == length(platforms) ? option_args : non_register_option_args

    pref_llvm = sanitize(platform) == "memory" ? msan_preferred_llvm_version : preferred_llvm_version

    build_tarballs(args, name, version, sources, script, [platform], products, dependencies;
                   preferred_gcc_version=v"5", preferred_llvm_version=pref_llvm,
                   julia_compat="1.6")
end
