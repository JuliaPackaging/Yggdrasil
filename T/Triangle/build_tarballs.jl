using BinaryBuilder

name = "Triangle"
version = v"1.6.1"

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
sources = [
    GitSource("https://github.com/JuliaGeometry/Triangulate.jl.git","b2ffb23ca7d89c567fd31367882bd216757cdb9c")
]

script = raw"""
cd $WORKSPACE/srcdir/Triangulate.jl/deps/src
mkdir -p "${libdir}"

# Patch the code in order to replace exit() calls in the C code  so that we can
# throw an error instead.
sed -e "s/  exit/extern void error_exit(int); error_exit/g" triangle/triangle.c > triangle_patched.c

# Concerning the suppression of int - pointer cast warnings,
# see the following comment in triangle.c:
#
# encode() compresses an oriented triangle into a single pointer.  It 
# relies on the assumption that all triangles are aligned to four-byte
# boundaries, so the two least significant bits of (otri).tri are zero.
#
# So there is an inherent hack in the code which we have to allow and hope things keep working.
$CC -Itriangle  -Wno-int-to-pointer-cast  -Wno-pointer-to-int-cast -DREAL=double -DTRILIBRARY -O3 -fPIC -DNDEBUG -DNO_TIMER -DEXTERNAL_TEST $LDFLAGS --shared -o "${libdir}/libtriangle.${dlext}" triangle_patched.c triwrap.c

install_license triangle/README
"""

platforms = supported_platforms(; experimental=true)
products = [LibraryProduct("libtriangle", :libtriangle)]
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies, julia_compat="1.6")

