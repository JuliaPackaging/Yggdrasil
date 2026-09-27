using BinaryBuilder

name = "Triangle"

version = v"1.6.2"
ygg_version = v"1.6.3"

sources = [
    GitSource("https://github.com/JuliaGeometry/Triangle.git","2ef9213abd06f2dd6312b9ee90758fe91226c6b7")
]

script = raw"""

cd $WORKSPACE/srcdir/Triangle

mkdir -p "${libdir}"

GENERICFLAGS=(-DREAL=double  -DTRILIBRARY  -DNDEBUG -DNO_TIMER -DEXTERNAL_TEST)

if [[ "${target}" == x86_64-w64-mingw32 ]]; then
    ARCHFLAGS=(-DULONG="unsigned long long")
else
    ARCHFLAGS=(-DULONG="unsigned long")
fi

$CC "${ARCHFLAGS[@]}"  "${GENERICFLAGS[@]}" -O3 -fPIC -shared -o "${libdir}/libtriangle.${dlext}" triangle.c triwrapjulia.c

# Triangle's struct layout depends on REAL.  libtriangle is built with
# REAL=double; prepend a default to triangle.h so header consumers match
# that ABI without having to define REAL themselves.
mkdir -p ${includedir}
{
    echo '#ifndef REAL'
    echo '#define REAL double'
    echo '#endif'
    cat triangle.h
} > ${includedir}/triangle.h

install_license README
"""

platforms = supported_platforms()

products = [LibraryProduct("libtriangle", :libtriangle)]

dependencies = Dependency[]

build_tarballs(ARGS, name, ygg_version, sources, script, platforms, products, dependencies, julia_compat="1.6")
