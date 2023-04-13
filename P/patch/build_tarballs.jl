using BinaryBuilder

name = "patch"
version = v"2.7.6"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/patch/patch-$(version).tar.xz",
                  "ac610bda97abe0d9f6b7c963255a11dcb196c25e337c61f94e4778d632f1d8fd"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/patch*
./configure --prefix=${prefix} --host=${target}
make -j${nproc}
make install
"""

# Windows build fails spectacularly; some patching required
platforms = filter(!Sys.iswindows, supported_platforms())
products = [
    ExecutableProduct("patch", :patch),
]
dependencies = Dependency[]
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
