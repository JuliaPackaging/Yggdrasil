include("../common.jl")

version = v"17.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "38e0a0dda82ab2807d7064b34bd7e81034ef3837")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"17.0.6")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
