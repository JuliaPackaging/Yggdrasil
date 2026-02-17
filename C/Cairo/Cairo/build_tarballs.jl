include(joinpath("..", "common.jl"))

name = "Cairo"

# Dependencies: common set plus LZO
dependencies = [
    common_dependencies;
    # Build with LZO errors on macOS:
    # /workspace/destdir/include/lzo/lzodefs.h:2197:1: error: 'lzo_cta__3' declared as an array with a negative size
    Dependency("LZO_jll"; compat="2.10.3", platforms=filter(!Sys.isapple, platforms));
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies;
               clang_use_lld=false, julia_compat="1.6", preferred_gcc_version=v"8")
