using BinaryBuilder

name = "Luna"
version = v"0.26.2"

sources = [
    GitSource("https://github.com/remnrem/luna-base.git",
              "6155a550c534feb32e816ed3869c45f8ddc9b78a"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/luna-base
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_it.patch
mkdir -p ${libdir}
mkdir -p ${bindir}
def_windows=""
if [[ ${target} == *-apple-* ]]; then
    suspicious_arch="MAC"
elif [[ ${target} == *-mingw* ]]; then
    suspicious_arch="WINDOWS"
    def_windows="WINDOWS=1"
else
    suspicious_arch="LINUX"
fi
make -j${nproc} ARCH=${suspicious_arch} FFTW=${prefix} PREFIX=${prefix} LIBDIR=${libdir} ${def_windows}
cp "luna${exeext}" "${bindir}/"
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
