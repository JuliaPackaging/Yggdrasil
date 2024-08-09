using BinaryBuilder

name = "Rmath"
version = v"0.4.2"

sources = [
    GitSource("https://github.com/JuliaStats/Rmath-julia.git",
              "18dcd7c259b031c3ce9c275b7dd136585d126017"),
]

script = raw"""
cd $WORKSPACE/srcdir/Rmath-julia*
# The whole `USEGCC`/`USECLANG` business is wrong and backword. Until this this fixed upstream
# (https://github.com/JuliaStats/Rmath-julia/issues/47),
# we have to set `USEGCC`/`USECLANG` ourselves.
if [[ ${target} == *-apple-* ]] || [[ ${target} == *-freebsd* ]]; then
   USECLANG=1
   USEGCC=0
else
   USECLANG=0
   USEGCC=1
fi
make -j${nproc} USECLANG=${USECLANG} USEGCC=${USEGCC}
mkdir -p "${libdir}"
mv src/libRmath-julia.* "${libdir}"
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libRmath-julia", :libRmath),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat = "1.6")
