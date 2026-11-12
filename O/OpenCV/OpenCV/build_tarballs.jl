using BinaryBuilder, Pkg

name = "OpenCV"

include(joinpath(@__DIR__, "..", "common.jl"))

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)
filter!(p -> !(arch(p) == "aarch64" && Sys.isfreebsd(p)), platforms)
filter!(p -> arch(p) != "armv6l", platforms)
filter!(p -> arch(p) != "riscv64", platforms)

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
    julia_compat = libjulia_julia_compat(julia_versions),
    preferred_gcc_version = v"10")
