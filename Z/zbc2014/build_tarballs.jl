using BinaryBuilder

name = "libzbc2014"
version = v"0.3.0"
sources = [
     GitSource("https://github.com/guestdaniel/ZBC2014.jl_CSource.git", "861db9fc377ae632ff7af0aab7ace8e815c445b6"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/ZBC2014.jl_CSource
${CC} -c -fPIC complex.c -o complex.o
${CC} -c -fPIC model_IHC.c -o model_IHC.o
${CC} -c -fPIC model_Synapse.c -o model_Synapse.o
${CC} -shared -o "libzbc2014.${dlext}" model_IHC.o model_Synapse.o complex.o
mkdir ${libdir}
cp "libzbc2014.${dlext}" ${libdir}
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libzbc2014", :libzbc2014)
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
