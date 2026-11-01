include("../common.jl")

# Julia 1.9 would select the `sanitize+memory` artifact on x86_64-linux-gnu
# (it picks the lexicographically last matching triplet), so require Julia 1.10.
build_pcre2(ARGS, "PCRE2_16_32", v"10.49", [16, 32]; julia_compat="1.10")
