include("../common.jl")

version_string = "2.8"
version = VersionNumber(version_string)
# We bumped the version because we built for new architectures
ygg_version = v"2.8.1"

sources = gsl_sources(version_string, "6a99eeed15632c6354895b1dd542ed5a855c0f15d9ad1326c6fe2b2c9e423190")

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies; julia_compat="1.6")
