# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
include(joinpath("..", "common.jl"))

name = "FFplay"

# The products that we will ensure are always built
products = [
    ExecutableProduct("ffplay", :ffplay),
]

# Dependencies that must be installed before this package can be built
# TODO: Theora once it's available
dependencies = [
    HostBuildDependency("YASM_jll"),
    BuildDependency("nv_codec_headers_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("LibVPX_jll"), # We use the static archive
    Dependency("FFMPEG_jll"; compat=string(version)),
    Dependency("SDL2_jll"),
]

# FFplay 4.4.4 does not build on aarch64-apple
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script(; ffplay=true), platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=preferred_gcc_version)
