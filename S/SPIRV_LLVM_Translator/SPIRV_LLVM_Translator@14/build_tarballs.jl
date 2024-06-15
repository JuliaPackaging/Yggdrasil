include("../common.jl")

version = v"14.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "62f5b09b11b1da42274371b1f7535f6f2ab11485")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"14.0.6")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
