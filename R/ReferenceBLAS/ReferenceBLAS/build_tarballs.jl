name = "ReferenceBLAS"

include("../common.jl")

script = blas_script(blas32=false)

products = [
    LibraryProduct("libblas", :libblas),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")

# Build Trigger: 5
