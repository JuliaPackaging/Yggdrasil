using BinaryBuilder

name = "Luna"
version = v"0.23.0"

sources = [
    GitSource("https://bitbucket.org/remnrem/luna-base.git",
              "6d333a4034f7022ba4d1aa99ce2f8afddfd6832e"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/luna-base
mkdir -p ${libdir}
mkdir -p ${bindir}
if [[ ${target} == *-apple-* ]]; then
    supicious_arch="MAC"
elif [[ ${target} == *-mingw* ]]; then
    suspicious_arch="WINDOWS"
else
    suspicious_arch="LINUX"
fi
make -j${nproc} ARCH=${suspicious_arch}
cp luna ${bindir}/
cp libluna* ${libdir}/
install_license LICENSE.txt
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("luna", :luna),
    LibraryProduct("libluna", :libluna),
]

dependencies = [
    "FFTW_jll",
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
