name = "LAPACK32"

include("../common.jl")

script = lapack_script(lapack32=true)

products = [
    LibraryProduct("liblapack32", :liblapack32),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.9", preferred_gcc_version=v"6")

# Build Trigger: 2
