include("../common.jl")

version = v"13.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "093cf279cad6f12bb22abf0a94eae9aca938aaea")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"13.0.1")),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"10", julia_compat="1.6")
