using BinaryBuilder

name = "autoconf"
version = v"2.73"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftpmirror.gnu.org/gnu/autoconf/autoconf-$(version.major).$(version.minor).tar.xz",
                  "9fd672b1c8425fac2fa67fa0477b990987268b90ff36d5f016dae57be0d6b52e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/autoconf*/
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/relocatable-autoconf.patch
touch man/*
autoreconf -f -i
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} PERL="/usr/bin/env perl"
make -j${nproc}
make install
"""

platforms = [AnyPlatform()]
products = [
    FileProduct("bin/autoconf", :autoconf),
]

dependencies = Dependency[
]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
