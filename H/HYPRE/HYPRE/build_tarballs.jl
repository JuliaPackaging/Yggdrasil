include("../common.jl")

name = "HYPRE"

platforms, platform_dependencies = MPI.augment_platforms(supported_platforms())

products = [
    LibraryProduct("libHYPRE", :libHYPRE),
]

build_tarballs(ARGS, name, ygg_version, sources, hypre_script(; bigint=false), platforms, products,
               hypre_dependencies(platforms, platform_dependencies);
               augment_platform_block, julia_compat="1.10", preferred_gcc_version=v"8")
