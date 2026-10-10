include("../common.jl")

# Build curl 8.21 with statically linked zstd support, as Julia stdlib for older versions of Julia.
# We do not want to add zstd as stdlib in patch releases of these Julia versions.

# Therefore, we build `LibCURL_jll` 8.21.1. It supports zstd compression, but does not depend on `Zstd_jll`.
# Instead, zstd support is linked in statically.
# This is functionally the same ais version 8.21.0, but does not depend on `Zstd_jll`.

# The current version of `LibCURL_jll` is 8.22.0, so all downstream users which do not explicitly
# request version 8.21 will not see our special build. And if they do, little harm is done,
# since there is no change in functionality (zstd compression is still supported).

build_libcurl(ARGS, "LibCURL", v"8.21.0"; ygg_version=v"8.21.1", with_zstd=true, static_zstd=true)

# Build trigger: 0
