name = "ReferenceBLAS32"

include("../common.jl")

script = blas_script(blas32=true)

products = [
    LibraryProduct("libblas32", :libblas32),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"6")

# Build Trigger: 1
