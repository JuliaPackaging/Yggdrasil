include("../coin-or-common.jl")

version = offset_version(v"6.2.0", v"0.0.1")

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

make CFLAGS="$CFLAGS" LIBS="$LIBS" CC="$CC"
make install

cd lib

all_load="--whole-archive"
noall_load="--no-whole-archive"
if [[ "${target}" == *-apple-* ]]; then
  all_load="-all_load"
  noall_load="-noall_load"
fi

mkdir -p ${libdir}
${CC} -fopenmp -fPIC -shared -Wl,${all_load} libsdp.a -Wl,${noall_load} -o ${libdir}/libcsdp.${dlext} -lgomp -lopenblas -lm
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcsdp", :libcsdp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well
build_tarballs(
    ARGS,
    "CSDP",
    version,
    sources,
    script,
    platforms,
    products,
    dependencies;
    preferred_gcc_version = gcc_version,
    julia_compat = "1.6",
)
