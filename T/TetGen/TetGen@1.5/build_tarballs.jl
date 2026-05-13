using BinaryBuilder

name = "TetGen"
version = v"1.5.4"

# Artifact builder for TetGen (c) Hang Si, see project home page https://tetgen.org
# TetGen's license is  AGPLv3.
#
# TetGen source is C++ code, interfacing to Julia works via C wrapper by Simon Danisch
# in the cwrapper subdirectory.
#
# For the 1.5.x series, the patch version of the build script is increased along with the
# improvements in the wrapper API.

sources = [
    GitSource("https://github.com/ufz/tetgen.git","3f75905af7407ab0de1cd1dc92a1b77d6bdacbb7"),
    DirectorySource("cwrapper",target="cwrapper")
]



script = raw"""
mkdir -p ${libdir}

cd $WORKSPACE/srcdir/tetgen

mv tetgen.h tmp.h
sed -e "s/class tetgenio {/class tetgenio { void * operator new(size_t n) {  return malloc(n);} void operator delete(void* p) noexcept {free(p);} /g" tmp.h > tetgen.h

mv tetgen.cxx tmp.cxx
sed -e "s/tetrahedrons->items \* 10/(tetrahedrons->items + 100) * 10/g" tmp.cxx > tetgen.cxx

# Compile and link together with C wrapper
${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY -I. ${WORKSPACE}/srcdir/cwrapper/cwrapper.cxx -o cwrapper.o
${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY tetgen.cxx -o tetgen.o
${CXX} -c -fPIC -std=c++11 -O3 -c -DTETLIBRARY predicates.cxx -o predicates.o
${CXX} $LDFLAGS -shared -fPIC tetgen.o predicates.o  cwrapper.o -o ${libdir}/libtet.${dlext}

install_license LICENSE
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libtet", :libtet)
]
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")
