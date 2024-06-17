using BinaryBuilder, Pkg

name = "libtree"
version = v"3.1.1"

sources = [
    ArchiveSource("https://github.com/haampie/libtree/archive/refs/tags/v$(version).tar.gz",
                  "6148436f54296945d22420254dd78e1829d60124bb2f5b9881320a6550f73f5c")
]

script = raw"""
cd $WORKSPACE/srcdir/libtree-*/
make CFLAGS="-Os -fwhole-program" LDFLAGS="-Wl,-s" "PREFIX=$prefix" install
"""

# Build only on platforms where ELF objects are usually used.
platforms = filter!(p -> Sys.islinux(p) || Sys.isfreebsd(p), supported_platforms(; experimental=true))

products = [
    ExecutableProduct("libtree", :libtree)
]

dependencies = Dependency[]

# Note: binutils 2.24 has issues with -s and --gc-sections, so use GCC 5 which comes wth a later binutils.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5")
