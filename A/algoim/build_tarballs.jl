using BinaryBuilder

name = "algoim"
version = v"0.1.0"
sources = [
    GitSource("https://github.com/ericneiva/algoim.git", "e80020a5182597a2392194651f62fb6f4c631082"),
] # Required to compile with Apple's clang 16. 
# See https://github.com/algoim/algoim/pull/8 and https://github.com/algoim/algoim/pull/6

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
