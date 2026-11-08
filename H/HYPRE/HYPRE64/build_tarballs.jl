include("../common.jl")

name = "HYPRE64"

push!(sources, DirectorySource("./bundled"))

platforms = supported_platforms()
# 64-bit indices are for problems too large to address on 32-bit platforms
filter!(p -> nbits(p) == 64, platforms)
platforms, platform_dependencies = MPI.augment_platforms(platforms)

products = [
    LibraryProduct("libHYPRE64", :libHYPRE64),
]

build_tarballs(ARGS, name, ygg_version, sources, hypre_script(; bigint=true), platforms, products,
               hypre_dependencies(platforms, platform_dependencies);
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"8")
