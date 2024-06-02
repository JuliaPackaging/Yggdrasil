name = "blis"

include("../common.jl")

script = blis_script(blis32=false)

products = [
    LibraryProduct("libblis", :blis)
]
 
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"11", lock_microarchitecture=false, julia_compat="1.6")
