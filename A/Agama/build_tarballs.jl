using BinaryBuilder, Pkg

name = "Agama"
repo = "https://github.com/GalacticDynamics-Oxford/Agama.git"

version = v"1.0"
sources = [
    GitSource(repo, "f392b9d6e59269d451b37b3ada2508a44bd3a80c"),
]

platforms = supported_platforms(;exclude=x->Sys.iswindows(x) || Sys.isfreebsd(x) || (libc(x) == "musl"))
platforms = expand_cxxstring_abis(platforms)

products = [
    LibraryProduct("libagama", :libagama),
]

dependencies = [
    Dependency("GSL_jll", compat="~2.8.1"),
    Dependency("LLVMOpenMP_jll"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

script = raw"""
cd $WORKSPACE/srcdir/Agama

# Make the Makefile.local
echo "
LINK = \$(CXX)

COMPILE_FLAGS_ALL += -fPIC -fopenmp -Wall -O2 
LINK_FLAGS_ALL += -fopenmp
COMPILE_FLAGS_ALL += -std=c++11

COMPILE_FLAGS_LIB += -I${includedir}
LINK_FLAGS_LIB_AND_EXE_STATIC += -L${libdir} -lgsl -lgslcblas
" > Makefile.local

# Generate the library
make -j${nproc} "libagama.${dlext}" LIBNAME_SHARED="libagama.${dlext}"

# Install
install -Dvm 755 libagama.${dlext} -t ${libdir}
"""

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
