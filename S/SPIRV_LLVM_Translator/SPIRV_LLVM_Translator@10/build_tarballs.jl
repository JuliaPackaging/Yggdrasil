include("../common.jl")

version = v"10.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "ab5e12aa84fd95d7b0cd7b7b3f27e6ea5eaba05e")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"10.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"10.0.1"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")
