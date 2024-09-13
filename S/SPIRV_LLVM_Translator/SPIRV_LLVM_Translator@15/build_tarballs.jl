version = v"15.0"
llvm_version = v"15.0.7"
include("../common.jl")

# Collection of sources required to build attr
sources = [GitSource(repo, "1e170e22f65d6bf01e6c592f8ed845dcceb69bea")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
