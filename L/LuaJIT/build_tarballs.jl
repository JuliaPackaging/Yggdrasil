using BinaryBuilder

name = "LuaJIT"
# NOTE: LuaJIT has effectively moved to a "rolling release" model where users are
# expected to track either the `v2.1` or `v2.0` branch of the Git repository rather
# than relying on formal releases. We'll translate that to Yggdrasil versioning by
# using the date of the commit passed to `GitSource` as the patch number with the
# upstream version as the major and minor parts of the version. Whenever, if ever,
# Mike Pall decides to make e.g. a v2.1.0 release, we'll have to continue to use this
# system for it rather than reflecting the upstream version.
version = v"2.1.20221221"

sources = [GitSource("https://luajit.org/git/luajit.git",
                     "a04480e311f93d3ceb2f92549cad3fffa38250ef")]

script = raw"""
cd ${WORKSPACE}/srcdir/LuaJIT-*

make -j${nproc} amalg \
    PREFIX="${prefix}" \
    HOST_CC="${CC_BUILD} -m${nbits}" \
    STATIC_CC="${CC}" \
    DYNAMIC_CC="${CC} -fPIC" \
    CROSS="" \
    TARGET_LD="${CC}"
make install PREFIX="${prefix}"
"""

platforms = filter!(p -> arch(p) !== :powerpc64le, supported_platforms())

products = [ExecutableProduct("luajit", :luajit),
            LibraryProduct(["libluajit-5.1", "lua51"], :libluajit)]

dependencies = []

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
