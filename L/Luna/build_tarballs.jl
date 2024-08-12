using BinaryBuilder

name = "Luna"
version = v"0.28.0"

sources = [
    GitSource("https://github.com/remnrem/luna-base.git",
              "f209d9e42bd3d2ddec72223c64f7249fe4a2b583"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/luna-base
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/fix_it.patch
def_windows=""
if [[ ${target} == *-apple-* ]]; then
    suspicious_arch="MAC"
elif [[ ${target} == *-mingw* ]]; then
    suspicious_arch="WINDOWS"
    def_windows="WINDOWS=1"
else
    suspicious_arch="LINUX"
fi
make -j${nproc} ARCH=${suspicious_arch} FFTW=${prefix} PREFIX=${prefix} LIBDIR=${libdir} SHARED_LIB=libluna.${dlext} ${def_windows}
install -Dvm 0755 "luna${exeext}" "${bindir}/luna${exeext}"
install -Dvm 0755 "libluna.${dlext}" "${libdir}/libluna.${dlext}"
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

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"5")
