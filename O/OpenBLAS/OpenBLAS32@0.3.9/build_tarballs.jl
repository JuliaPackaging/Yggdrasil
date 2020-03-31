using BinaryBuilder

include("../common.jl")


# Collection of sources required to build OpenBLAS
name = "OpenBLAS32"
version = v"0.3.9"

sources = openblas_sources(version)
script = openblas_script(openblas32=true)
platforms = openblas_platforms()

products = [
    LibraryProduct("libopenblas", :libopenblas)
]

dependencies = Dependency[]

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
