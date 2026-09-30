include("../common.jl")

# Build curl 8.21 without zstd support, as Julia stdlib for older versions of Julia.
# We do not want to add zstd as stdlib in patch releases of these Julia versions.
#
# It is not straightforward to provide a LibCURL without zstd support which does not
# confuse people or lead to inconsistencies. We use the following approach:
# - The current curl is 8.22, we build 8.21 (and older version) to be "out of the way".
# - Since 8.21.0 exists (with zstd), we build 8.21.1 without zstd, and 8.21.2 with zstd again.
#   This ensures that a "naive" user will not see our 8.21.1 which lacks zstd support.
#   You need to use 8.21.1 explicitly to avoid zstd support.

build_libcurl(ARGS, "LibCURL", v"8.21.0"; ygg_version=v"8.21.2", with_zstd=true)

# Build trigger: 0
