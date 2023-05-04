name = "LAPACK"

include("../common.jl")

script = lapack_script(lapack32=false)

products = [
    LibraryProduct(["liblapack64"], :liblapack64),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10", preferred_gcc_version=v"6")
