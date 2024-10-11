using BinaryBuilder

name = "algoim"
version = v"0.1.0"
sources = [
    GitSource("https://github.com/pantolin/algoim.git", "a4379af4e3d8a9075c34f774fbb0bb88c8ccca08"),
] # Required to compile with Apple's clang 16. See https://github.com/algoim/algoim/pull/8

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
