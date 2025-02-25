version = v"17.0"
llvm_version = v"17.0.6"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "499f26a2aa41956d153dac83993e7fc7e2551323")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
