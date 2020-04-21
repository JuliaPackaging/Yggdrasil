include("../common.jl")

version = v"9.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "17b72562e002a4653e31829e89cf14ce35892896")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"9.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"9.0.1"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")
