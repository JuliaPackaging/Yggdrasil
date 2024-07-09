version = v"17.0"
llvm_version = v"17.0.6"
include("../common.jl")

# Collection of sources required to build attr
sources = [GitSource(repo, "38e0a0dda82ab2807d7064b34bd7e81034ef3837")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
