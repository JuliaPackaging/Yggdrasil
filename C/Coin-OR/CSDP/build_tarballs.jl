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

atomic_patch -p1 "${WORKSPACE}/srcdir/patches/blegat.patch"
atomic_patch -p1 "${WORKSPACE}/srcdir/patches/makefile.patch"

if [[ ${nbits} == 32 ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/32bits_platforms.patch"
fi

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/mac_freebsd.patch"
fi

if [[ "${target}" == powerpc* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/powerpc.patch"
fi

if [[ "${target}" == arm* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/arm.patch"
fi

if [[ "${target}" == aarch* ]]; then
    atomic_patch -p1 "${WORKSPACE}/srcdir/patches/aarch.patch"
fi

make -j${nproc}
make install
mkdir -p ${bindir}
cp /usr/local/bin/csdp ${bindir}/csdp

if [[ "${target}" == *-mingw* ]]; then
    mv "${bindir}/csdp" "${bindir}/csdp${exeext}"
fi

cd lib
ar x libsdp.a
cc -shared -o "libcsdp.${dlext}" *.o
rm *.o
cp libcsdp.${dlext} ${libdir}/libcsdp.${dlext}
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
