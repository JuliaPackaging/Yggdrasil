include("../common.jl")

version = v"8.0"

# Collection of sources required to build attr
sources = [GitSource(repo, "343490ebc2a56c12d434233ceb8fba3aa1fbee98")]

# LLVM 8's add_llvm_library does not work on Windows
platforms = filter(!Sys.iswindows, platforms)

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(name="LLVM_full_jll", version=v"8.0.1")),
    #Dependency(PackageSpec(name="libLLVM_jll", version=v"8.0.1"))
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7", julia_compat="~1.4")

