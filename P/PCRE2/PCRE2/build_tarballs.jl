include("../common.jl")

# We bump the patch version because this package no longer provides the 16-bit and 32-bit libraries
build_pcre2(ARGS, "PCRE2", v"10.49.1", [8])
