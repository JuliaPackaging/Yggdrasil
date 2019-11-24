using BinaryBuilder

name = "LuaJIT"
version = v"2.0.5"

sources = [
    "https://luajit.org/download/LuaJIT-$(version).tar.gz" =>
        "874b1f8297c697821f561f9b73b57ffd419ed8f4278c82e05b48806d30c1e979",
]

script = raw"""
cd ${WORKSPACE}/srcdir/LuaJIT-*
make -j${nproc}
make install PREFIX="${prefix}"
"""

platforms = filter(supported_platforms()) do platform
    arch(platform) !== :aarch64 && arch(platform) !== :powerpc64le
end

products = [
    ExecutableProduct("luajit", :luajit),
    LibraryProduct(["libluajit-5.1", "lua51"], :libluajit),
]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
