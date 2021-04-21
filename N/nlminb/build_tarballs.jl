using BinaryBuilder

name = "nlminb"
version = v"0.1.0"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/geo-julia/nlminb.f.git",
              "6b2d460b866911e8bfca32b1217c08fb78c3111f"), # v0.1.0
]

# copied from SCALAPACK
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlminb.f
cd lib && tar -xzf blas-3.8.0.tgz \
    && cd BLAS-3.8.0 && make \
    && cd ../.. 

## compile by hand
if [[ ${target} == *aarch64* ]] || [[ ${target} == *arm* ]]; then
    FLAGS=""
else
    FLAGS="-mfpmath=sse -msse2 -mstackrealign"
fi
CCFLAGS="-fPIC -DNDEBUG  -Iinclude -O2 -Wall -std=gnu99 ${FLAGS}"
FCFLAGS="-fPIC -fno-optimize-sibling-calls -O2 ${FLAGS}"

gfortran ${FCFLAGS} -c src/portsrc.f -o src/portsrc.o 
gfortran ${FCFLAGS} -c src/d1mach.f -o src/d1mach.o 
gcc ${CCFLAGS} -c src/port2.c -o src/port.o
gfortran -shared -static-libgcc -lm -o ${libdir}/libnlminb.${dlext} src/portsrc.o src/d1mach.o src/port.o lib/BLAS-3.8.0/blas_LINUX.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
platforms = expand_gfortran_versions(platforms)
platforms = platforms[2:end]

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlminb", :libnlminb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
