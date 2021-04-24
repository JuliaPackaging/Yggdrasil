using BinaryBuilder

name = "nlminb"
version = v"0.1.0"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/geo-julia/nlminb.f.git",
              "6b2d460b866911e8bfca32b1217c08fb78c3111f"), # v0.1.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlminb.f

## compile by hand
if [[ "${proc_family}" == "intel" ]]; then
    FLAGS="-mfpmath=sse -msse2 -mstackrealign"
fi
CFLAGS="-fPIC -DNDEBUG  -Iinclude -O2 -Wall -std=gnu99 ${FLAGS}"
FFLAGS="-fPIC -fno-optimize-sibling-calls -O2 ${FLAGS}"

gfortran ${FFLAGS} -c src/portsrc.f -o src/portsrc.o 
gfortran ${FFLAGS} -c src/d1mach.f -o src/d1mach.o 
gcc ${CFLAGS} -c src/port2.c -o src/port.o
gfortran -shared -static-libgcc -lm -o ${libdir}/libnlminb.${dlext} src/portsrc.o src/d1mach.o src/port.o -lopenblas
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlminb", :libnlminb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("OpenBLAS32_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
