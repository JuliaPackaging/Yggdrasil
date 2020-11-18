include("../common.jl")

version = v"11.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "db02e6a3bb872abd3c8d8971c17a53d12cab9bc4")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"11.0.0")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"11.0.0"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.6")
