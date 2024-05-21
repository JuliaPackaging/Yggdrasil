include("../common.jl")

name = "CXSparse"
version = v"4.4.0"
SS_version_str = "7.7.0"
SS_version = VersionNumber(SS_version_str)

sources = suitesparse_sources(SS_version)

# Bash recipe for building across all platforms
script = raw"""
PROJECTS_TO_BUILD="cxsparse"
CMAKE_OPTIONS+=(
        -DSUITESPARSE_USE_SYSTEM_SUITESPARSE_CONFIG=ON
    )
""" * build_script(true)

# Add dependency on SuiteSparse_jll
dependencies = append!(dependencies, [
    Dependency("SuiteSparse_jll"; compat = "=$SS_version_str")
])
products = [
    LibraryProduct("libcxsparse", :libcxsparse)
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, 
               dependencies; julia_compat="1.11")

