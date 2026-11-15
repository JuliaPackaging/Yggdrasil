using BinaryBuilder

name = "automake"
version_str = "1.20"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/automake/automake-$(version_str).tar.xz",
                  "f6f34dad4cbe395715762b0710f7c511e39bd5cf777e6b95818ccbecf7714248")
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
