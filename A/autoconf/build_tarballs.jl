using BinaryBuilder

name = "autoconf"
version = v"2.72"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/autoconf/autoconf-$(version.major).$(version.minor).tar.xz",
                  "ba885c1319578d6c94d46e9b0dceb4014caafe2490e437a0dbca3f270a223f5a"),
    DirectorySource("./patches"; target="patches"),
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
