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
    BuildDependency("nv_codec_headers_jll"),
    BuildDependency("Xorg_xorgproto_jll"),
    BuildDependency("LibVPX_jll"), # We use the static archive
    Dependency(PackageSpec(name="FFMPEG_jll", version=version)),
    Dependency("SDL2_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script(; ffplay=true), platforms, products, dependencies; preferred_gcc_version=preferred_gcc_version)
