name = "LAPACK"

include("../common.jl")
script = lapack_script(lapack32=false)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
