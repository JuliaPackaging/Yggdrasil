using BinaryBuilder

# Collection of sources required to build Arpack
name = "Arpack32"

version = v"3.9.1"
ygg_version = v"3.9.2"

include("../common.jl")

# The products that we will ensure are always built
products = [
    LibraryProduct("libarpack", :libarpack32),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, ygg_version, arpack_sources(version), build_script(build_32bit=true),
               platforms, products, dependencies;
	       julia_compat="1.10")

# Build trigger: 1
