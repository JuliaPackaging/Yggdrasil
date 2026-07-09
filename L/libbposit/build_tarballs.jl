# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libbposit"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/jamesquinlan/libbposit.git",
              "fe280133cdb52a4375bd93a17ab0b4f62b38248d"),
]

# Pure-C99 build: compile the single translation unit, link as a shared
# library, install to ${libdir}.  The Makefile hardcodes TARGET=libbposit.so,
# so we bypass it and call the cross-compiler directly.
script = raw"""
cd ${WORKSPACE}/srcdir/libbposit
${CC} -Iinclude -fPIC -O3 -c src/bposit.c -o bposit.o
${CC} -shared -o ${libdir}/libbposit.${dlext} bposit.o -lm
install_license LICENSE
"""

# __int128 is a 64-bit-only GCC/Clang extension; exclude 32-bit targets.
platforms = supported_platforms()
filter!(p -> nbits(p) == 64, platforms)

products = [
    LibraryProduct("libbposit", :libbposit),
]

dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
