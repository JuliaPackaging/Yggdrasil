include("../common.jl")

version_string = "2.7.1"
version = VersionNumber(version_string)
# 2.7.2 was taken by the first build of upstream 2.7.1 (ABI differs from the earlier fake
# 2.7.1 build); 2.7.3 adds new platforms and a newer JLLWrappers compat.
ygg_version = v"2.7.3"

sources = gsl_sources(version_string, "dcb0fbd43048832b757ff9942691a8dd70026d5da0ff85601e52687f6deeb34b")

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
