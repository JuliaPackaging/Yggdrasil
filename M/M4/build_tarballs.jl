using BinaryBuilder

name = "M4"
version = v"1.4.21"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/m4/m4-$(version).tar.xz",
                  "f25c6ab51548a73a75558742fb031e0625d6485fe5f9155949d6486a2408ab66"),
]

script = raw"""
cd $WORKSPACE/srcdir/m4-*

if [[ "${target}" == *mingw* ]]; then
    export CFLAGS="-fstack-protector ${CFLAGS}"
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nprocs}
make install
"""

platforms = supported_platforms()

products = [
    ExecutableProduct("m4", :m4),
]

dependencies = Dependency[
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
