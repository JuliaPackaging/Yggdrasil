include("../common.jl")

name = "HYPRE"

platforms, platform_dependencies = MPI.augment_platforms(supported_platforms())

products = [
    LibraryProduct("libHYPRE", :libHYPRE),
]

dependencies = [
    hypre_dependencies(platforms, platform_dependencies);
    # Loading it forwards its LP64 BLAS/LAPACK into libblastrampoline; Julia only fills the ILP64 interface
    RuntimeDependency("OpenBLAS32_jll"; compat="0.3.33")
]

build_tarballs(ARGS, name, ygg_version, sources, hypre_script(; bigint=false), platforms, products, dependencies;
               augment_platform_block, julia_compat="1.11", preferred_gcc_version=v"8")
