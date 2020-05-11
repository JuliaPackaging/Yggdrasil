include("../common.jl")

version = v"10.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "7743482f2053582be990e93ca46d15239c509c9d")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"10.0.0")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"10.0.0"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")
