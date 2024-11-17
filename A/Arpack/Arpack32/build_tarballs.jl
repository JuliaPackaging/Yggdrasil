using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack32"

version = v"3.9.1"

include("../common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct("libarpack", :libarpack32),
]

# Dependencies that must be installed before this package can be built
append!(dependencies, [Dependency("OpenBLAS32_jll")])

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, arpack_sources(version), build_script(build_32bit=true),
               platforms, products, dependencies;
	       julia_compat="1.6", clang_use_lld=false, preferred_gcc_version=v"6")
