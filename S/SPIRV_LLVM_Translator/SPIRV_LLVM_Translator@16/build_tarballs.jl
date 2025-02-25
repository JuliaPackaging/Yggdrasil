version = v"16.0"
llvm_version = v"16.0.6"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "252b6d29e6d631526cf27a9055473e999f30ccce")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
