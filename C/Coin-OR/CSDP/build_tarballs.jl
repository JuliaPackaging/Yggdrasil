include("../coin-or-common.jl")

name = "CSDP"
version = v"6.2.0"

# Collection of sources required to build Clp
sources = [
    GitSource("https://github.com/coin-or/Csdp.git",
              "0dcf187a159c365b6d4e4e0ed5849f7b706da408"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Csdp*

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/blegat.patch

CFLAGS="-O2 -fPIC -fopenmp -ansi -Wall -DUSEOPENMP -DSETNUMTHREADS -DUSEGETTIME -I../include"
LIBS="-L../lib -lsdp -lopenblas -lm"

if [[ "${nbits}" == 64 ]] && [[ "${target}" != *aarch64* ]]; then
    CFLAGS="$CFLAGS -m64 -DBIT64"
fi

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
fi

make CFLAGS=$CFLAGS LIBS=$LIBS CC=$CC
make install
mkdir -p ${bindir}
cp /usr/local/bin/csdp ${bindir}/csdp

if [[ "${target}" == *-mingw* ]]; then
    mv "${bindir}/csdp" "${bindir}/csdp${exeext}"
fi

cd lib
ar x libsdp.a

mkdir -p ${libdir}
${CC} -shared -o "${libdir}/libcsdp.${dlext}" libsdp.a
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("csdp", :csdp),
    LibraryProduct("libcsdp", :libcsdp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=gcc_version)
