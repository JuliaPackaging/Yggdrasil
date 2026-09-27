using BinaryBuilder

name = "automake"
version = v"1.18.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/automake/automake-$(version).tar.xz",
                  "168aa363278351b89af56684448f525a5bce5079d0b6842bd910fdd3f1646887")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/automake*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} PERL="/usr/bin/env perl"
make -j${nproc}
make install
"""

platforms = [AnyPlatform()]
products = [
    FileProduct("bin/aclocal", :aclocal),
]

dependencies = [
    Dependency("autoconf_jll"),
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
