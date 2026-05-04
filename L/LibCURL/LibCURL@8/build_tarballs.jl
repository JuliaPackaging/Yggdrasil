include("../common.jl")

build_libcurl(ARGS, "LibCURL", v"8.20.0"; ygg_version=v"8.20.1", with_zstd=true)

# Build trigger: 0
