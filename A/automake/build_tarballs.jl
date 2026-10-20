using BinaryBuilder

name = "automake"
version_str = "1.19"
version = VersionNumber(version_str)

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/automake/automake-$(version_str).tar.xz",
                  "e3e2c2e3abf37898138db5b6c1d1dc35c9160c5978be7947d2c741705251d445")
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
