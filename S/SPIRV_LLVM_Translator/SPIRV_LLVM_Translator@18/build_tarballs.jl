version = v"18.0"
llvm_version = v"18.1.7"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "0a0ed3f735cd7a7f14c69b21d90679c6ac380eed")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
