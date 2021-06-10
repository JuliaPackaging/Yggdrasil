include("../common.jl")

version = v"12.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "67d3e271a28287b2c92ecef2f5e98c49134e5946")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"12.0.0")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"12.0.0"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.7")
