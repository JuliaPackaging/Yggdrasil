include("../common.jl")

version = v"9.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "8442f41802d8afaff9fd2b95396e9f82c8b5bf05")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"9.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")

