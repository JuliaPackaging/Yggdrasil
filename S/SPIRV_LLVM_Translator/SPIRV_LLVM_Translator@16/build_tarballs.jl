include("../common.jl")

version = v"16.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "0b107dbf421593ed6f201ea2b7976e9456bc6bd3")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"16.0.6")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
