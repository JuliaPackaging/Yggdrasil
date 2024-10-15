version = v"18.0"
llvm_version = v"18.1.7"
include("../common.jl")

# Collection of sources required to build attr
sources = [GitSource(repo, "242df2cb83e2322b456990fb0ca3e30bd9209ed0")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
