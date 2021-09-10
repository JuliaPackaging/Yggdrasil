using BinaryBuilder

name = "TetGen"
version = v"1.5.1"

#
# Artifact builder for TetGen (c) Hang Si, see project home page https://tetgen.org
# TetGen's license is  AGPLv3.
#
# TetGen source is C++ code, interfacing to Julia works via C wrapper by Simon Danisch
# in the cwrapper subdirectory.
#

#
# For 1.5.1 use the same upstream  source as in tetgenbuilder
# Tentative upstream source for 1.6:
# "http://www.tetgen.org/1.5/src/tetgen1.6.0.zip" => "e7bbbb4fb8f47f0adc3b46b26ab172557ebb90808c06e21b902b2166717af582"
sources = [
    GitSource("https://github.com/ufz/tetgen.git","150223d9416b5b75f5c1e50fda1ff7ba6f96871d"),
    DirectorySource("cwrapper",target="cwrapper")
]



script = raw"""
# This will be used for 1.6
# zipname=tetgen1.6.0
# cd $WORKSPACE/srcdir/$zipname

mkdir -p ${libdir}

cd $WORKSPACE/srcdir/tetgen

#
# Patch tetgen.h  with operators delegating new/delete to malloc/free for C/Julia compatibility
# Made corresponding feature request to upstream, probably available for 1.6.1
#

mv tetgen.h tmp.h
sed -e "s/class tetgenio {/class tetgenio { void * operator new(size_t n) {  return malloc(n);} void operator delete(void* p) noexcept {free(p);} /g" tmp.h > tetgen.h

#
# Fix crash of README example (see TetGen.jl#26)
# There seems to be a on-off error or something like this in the routine writing the result. In 1.6.0 and also in
# the previous 1.5 version this does not happen.
# 
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
# platforms=[Platform("x86_64", "linux"; libc="glibc")]

products = [
    LibraryProduct("libtet", :libtet)
]
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
