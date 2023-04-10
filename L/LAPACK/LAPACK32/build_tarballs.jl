name = "LAPACK32"

include("../common.jl")
script = lapack_script(lapack32=true)
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"6")
