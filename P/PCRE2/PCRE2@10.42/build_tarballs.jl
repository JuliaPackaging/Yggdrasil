include("../common.jl")

# Upstream 10.42 with the security fixes from its `release/pcre2-10.42` support branch,
# for Julia versions that still ship 10.42. The patch version is 1 because, like 10.49.1,
# this package only provides the 8-bit library.
build_pcre2(ARGS, "PCRE2", v"10.42.1", [8]; patches=true)
