using BinaryBuilder

name = "algoim"
version = v"0.1.1"
sources = [
    GitSource("https://github.com/algoim/algoim.git", "da1d81499608e1d499695d255f0233140b8c81e8"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/algoim
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
install_license LICENSE
mkdir -p "${includedir}"
cp -vr algoim "${includedir}/."
"""

platforms = [AnyPlatform()]

products = Product[]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
