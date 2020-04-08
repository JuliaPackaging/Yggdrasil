include("../coin-or-common.jl")

name = "CSDP"
version = v"6.2.0"

# Collection of sources required to build Clp
sources = [
    GitSource("https://github.com/coin-or/Csdp.git",
    "e1586e0413ef236b19abe5202f7e8392f3dd4614"),
    DirectorySource("./bundled"), 
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Csdp*

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

if [[ ! -d "${bindir}" ]]; then
  mkdir -p ${bindir}
fi

cp /usr/local/bin/csdp ${bindir}/csdp

if [[ "${target}" == *-mingw* ]]; then
    mv "${bindir}/csdp" "${bindir}/csdp${exeext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]

# The products that we will ensure are always built
products = [
    ExecutableProduct("csdp", :csdp),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               preferred_gcc_version=gcc_version)
