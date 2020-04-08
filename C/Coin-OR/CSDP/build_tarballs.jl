using BinaryBuilder

name = "CSDP"
version = v"6.2.0"

# Collection of sources required to build Clp
sources = [
    ArchiveSource("https://github.com/coin-or/Csdp/archive/releases/6.2.0.tar.gz",
    "3d341974af1f8ed70e1a37cc896e7ae4a513375875e5b46db8e8f38b7680b32f"),
    DirectorySource("./bundled"), 
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Csdp-releases-6.2.0/
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
  mkdir ${bindir}
fi

cp /usr/local/bin/csdp ${bindir}/csdp

if [[ "${target}" == *-mingw* ]]; then
    mv "${bindir}/csdp" "${bindir}/csdp${exeext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
