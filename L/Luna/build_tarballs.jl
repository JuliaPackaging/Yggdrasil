using BinaryBuilder

name = "Luna"
version = v"0.23.0"

sources = [
    GitSource("https://bitbucket.org/remnrem/luna-base.git",
              "6d333a4034f7022ba4d1aa99ce2f8afddfd6832e"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/luna-base
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/make_locations.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/malloc_stdlib.patch
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/no_cxx_override.patch
mkdir -p ${libdir}
mkdir -p ${bindir}
if [[ ${target} == *-apple-* ]]; then
    supicious_arch="MAC"
elif [[ ${target} == *-mingw* ]]; then
    suspicious_arch="WINDOWS"
else
    suspicious_arch="LINUX"
fi
make -j${nproc} ARCH=${suspicious_arch} FFTW=${prefix} PREFIX=${prefix} LIBDIR=${libdir}
cp "luna" "${bindir}/luna${exeext}"
cp "libluna.${dlext}" "${libdir}/"
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    ExecutableProduct("luna", :luna),
    LibraryProduct("libluna", :libluna),
]

dependencies = [
    Dependency("FFTW_jll"),
    Dependency("Zlib_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
