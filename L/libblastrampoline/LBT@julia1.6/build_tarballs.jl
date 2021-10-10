include("../common.jl")

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="=1.6",
               init_block = """
                 ccall((:lbt_forward, libblastrampoline), Int32, (Cstring, Int32, Int32), path, 1, 0)
               """
)
