version = v"19.0"
llvm_version = v"19.1.1"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "90a976491d3847657396456e0e94d7dc48d35996")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
