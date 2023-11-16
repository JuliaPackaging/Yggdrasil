name = "BLAS32"

include("../common.jl")

script = blas_script(blas32=true)

products = [
    LibraryProduct("libblas", :libblas),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
