using BinaryBuilder

name = "automake"
version = v"1.16"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/automake/automake-$(version.major).$(version.minor).tar.xz",
                  "f98f2d97b11851cbe7c2d4b4eaef498ae9d17a3c2ef1401609b7b4ca66655b8a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/automake*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

platforms = supported_platforms()
products = [
    FileProduct("bin/aclocal", :aclocal),
]

dependencies = [
    Dependency("autoconf_jll"),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
