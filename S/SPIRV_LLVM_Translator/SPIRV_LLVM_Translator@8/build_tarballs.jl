include("../common.jl")

version = v"8.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "20240c9e4284a839337a04fb6001d8bf6b26fb62")]

# LLVM 8's add_llvm_library does not work on Windows
platforms = filter(p -> !(p isa Windows), platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"8.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"8.0.1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")
