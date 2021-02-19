using BinaryBuilder, Pkg

name = "SuiteSparse"
version = v"5.8.1"

# Collection of sources required to build SuiteSparse
sources = [
    GitSource("https://github.com/DrTimothyAldenDavis/SuiteSparse.git",
              "1869379f464f0f8dac471edb4e6d010b2b0e639d"),
    DirectorySource("./bundled"),
]
