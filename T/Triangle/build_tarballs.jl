using BinaryBuilder

name = "Triangle"
version = v"1.6.0"

# Collection of sources required to build Triangle by J. Shewchuk
#
# More info:
# https://www.cs.cmu.edu/~quake/triangle.html
# https://github.com/JuliaGeometry/Triangulate.jl
#
# Please be aware that triunsuitable.c is not part of the original Triangle distribution.
# It provides the possibility to pass a cfunction created in Julia as  user refinement callback.
# For this reason at least triunsiutable.c must be downloaded from Triangulate.jl repo, and
# for simplicity, we do this for the whole code.
# We also patch the code in order to replace exit() calls in the C code  so that we can
# throw an error instead.
sources = [
    GitSource("https://github.com/JuliaGeometry/Triangulate.jl.git","b2ffb23ca7d89c567fd31367882bd216757cdb9c")
]



script = raw"""
cd $WORKSPACE/srcdir
cd Triangulate.jl/deps/src
if [[ ${target} == *-mingw32 ]]; then     libdir="bin"; else     libdir="lib"; fi
mkdir ${prefix}/${libdir}
sed -e "s/  exit/extern void error_exit(int); error_exit/g" triangle/triangle.c > triangle_patched.c
$CC -Itriangle -DREAL=double -DTRILIBRARY -O3 -fPIC -DNDEBUG -DNO_TIMER -DEXTERNAL_TEST $LDFLAGS --shared -o ${prefix}/${libdir}/libtriangle.${dlext} triangle_patched.c triwrap.c
"""


platforms = BinaryBuilder.supported_platforms()
products = [  LibraryProduct("libtriangle", :libtriangle) ]
dependencies = []
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

