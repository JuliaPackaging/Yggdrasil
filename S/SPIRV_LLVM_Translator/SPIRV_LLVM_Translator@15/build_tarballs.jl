version = v"15.0"
llvm_version = v"15.0.7"
include("../common.jl")

# Collection of sources required to build the package
sources = [GitSource(repo, "72538254527d23f48cef863c5ce3c3d804f94b8b")]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=llvm_version)),
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, get_script(llvm_version), platforms, products,
               dependencies; preferred_gcc_version=v"10", julia_compat="1.6")
