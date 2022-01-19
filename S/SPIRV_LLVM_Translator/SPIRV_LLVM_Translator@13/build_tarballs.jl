include("../common.jl")

version = v"13.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "776d9041e3baf120222e88842a9d441218a3f791")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"13.0.0")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"13.0.0"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="1.8")
