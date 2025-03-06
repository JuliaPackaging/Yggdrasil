using BinaryBuilder

name = "ECharts"
version = v"5.5.1"
sources = GitSource[]

script = "version=$(version)\n" * raw"""
apk add --update npm
cd ${prefix}
npm install echarts@${version}
install_license ${prefix}/node_modules/echarts/LICENSE
"""

platforms = [AnyPlatform()]

products = [
    FileProduct("node_modules/echarts/dist/echarts.js", :echarts),
]

dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
