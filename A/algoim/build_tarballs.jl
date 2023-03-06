using BinaryBuilder

name = "algoim"
version = v"0.1.0"
sources = [
    GitSource("https://github.com/algoim/algoim.git", "979cb3b7860b53751291352a929754d525b7fde1"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/algoim
install_license LICENSE
mkdir -p "${includedir}"
cp -vr algoim "${includedir}/."
"""

platforms = [AnyPlatform()]

products = Product[]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
