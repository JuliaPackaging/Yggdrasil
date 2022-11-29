using BinaryBuilder, Pkg

version = v"6.0.1"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
              "4faadddd6d373e1b85f567dc034e9eb9733247c7"),
]

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)
push!(platforms, Platform("x86_64", "linux"; sanitize="memory"))

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuitesparseconfig",   :libsuitesparseconfig),
    LibraryProduct("libamd",                 :libamd),
    LibraryProduct("libbtf",                 :libbtf),
    LibraryProduct("libcamd",                :libcamd),
    LibraryProduct("libccolamd",             :libccolamd),
    LibraryProduct("libcolamd",              :libcolamd),
    LibraryProduct("libcholmod",             :libcholmod),
    LibraryProduct("libldl",                 :libldl),
    LibraryProduct("libklu",                 :libklu),
    LibraryProduct("libumfpack",             :libumfpack),
    LibraryProduct("librbio",                :librbio),
    LibraryProduct("libspqr",                :libspqr),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"),
    BuildDependency("LLVMCompilerRT_jll",platforms=[Platform("x86_64", "linux"; sanitize="memory")]),
]
