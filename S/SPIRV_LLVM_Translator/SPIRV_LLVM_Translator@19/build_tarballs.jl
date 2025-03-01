version = v"19.0"
llvm_version = v"19.1.7"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "46004f6330f20b55563ca8b8b969cc5a00f35fc2")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
