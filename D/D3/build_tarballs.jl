using BinaryBuilder

name = "D3"
version = v"7.9.0"
sources = GitSource[]

script = "version=$(version)\n" * raw"""
apk add --update nodejs npm
cd ${prefix}
npm install d3@${version}
install_license ${prefix}/node_modules/d3/LICENSE
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("node_modules/d3/dist/d3.js", :d3),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
