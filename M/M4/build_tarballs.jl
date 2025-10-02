using BinaryBuilder

name = "M4"
version = v"1.4.20"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/m4/m4-$(version).tar.xz",
                  "e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b"),
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
