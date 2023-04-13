using BinaryBuilder

name = "M4"
version = v"1.4.19"

sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/m4/m4-$(version).tar.xz",
                  "63aede5c6d33b6d9b13511cd0be2cac046f2e70fd0a07aa9573a04a82783af96"),
]

script = raw"""
cd $WORKSPACE/srcdir/m4-*/

./configure --prefix=${prefix} --host=${target}
make -j${nprocs}
make install
"""

# Windows platforms fail with messages about `__memcpy_chk`
platforms = filter(p -> !Sys.iswindows(p), supported_platforms())

products = [
    ExecutableProduct("m4", :m4),
]

dependencies = [
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
