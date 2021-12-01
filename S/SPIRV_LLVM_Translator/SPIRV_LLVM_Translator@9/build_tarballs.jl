include("../common.jl")

version = v"9.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "d30dc2111d672c25a1969560021147289de4f823")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"9.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="~1.5")
