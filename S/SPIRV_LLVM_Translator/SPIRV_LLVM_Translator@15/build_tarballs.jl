version = v"15.0"
llvm_version = v"15.0.7"
include("../common.jl")

# Collection of sources required to build attr
sources = [GitSource(repo, "0f9ad6622b1bf308facf35073c91c738b34081ba")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
