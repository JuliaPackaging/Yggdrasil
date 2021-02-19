using BinaryBuilder, Pkg

name = "SuiteSparse"
version = v"5.8.1"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
              "1869379f464f0f8dac471edb4e6d010b2b0e639d"),
    DirectorySource("./bundled"),
]

# We enable experimental platforms as this is a core Julia dependency
platforms = supported_platforms(;experimental=true)

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
    LibraryProduct("libsuitesparse_wrapper", :libsuitesparse_wrapper),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libblastrampoline_jll"),
#    Dependency("METIS_jll"),
]
