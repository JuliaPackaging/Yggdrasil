using BinaryBuilder

name = "automake"
version_str = "1.20"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/automake/automake-$(version_str).tar.xz",
                  "6f7ae4c90b4e89b5f7f50a9c3bf205a10f18b60c2659d3d6f044351bd8a28d5d")
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
