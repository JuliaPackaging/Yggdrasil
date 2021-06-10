include("../common.jl")

version = v"11.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "52ba8426e7d2839807337339e17222b91a3b8e35")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"11.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"11.0.0"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="~1.6")
