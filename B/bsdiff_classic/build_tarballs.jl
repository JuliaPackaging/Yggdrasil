# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bsdiff_classic"
version = v"4.3.17"

# Collection of sources required to complete build
sources = [
    GitSource("https://salsa.debian.org/debian/bsdiff.git", "24b5474a87e495678d71cac7ba02493fb4fa483f")
]

# Bash recipe for building across all platforms
script = raw"""
cd bsdiff
atomic_patch -p1 $PWD/debian/patches/10-no-bsd-make.patch
atomic_patch -p1 $PWD/debian/patches/20-CVE-2014-9862.patch
perl -i -ple '$_ = "#include <sys/types.h>\n" . $_ if $. == 31' bspatch.c
cc -O3 -lbz2 bsdiff.c -o bsdiff
cc -O3 -lbz2 bspatch.c -o bspatch
install bsdiff bspatch "${bindir}"
install_license debian/copyright
"""

# Disable Windows for now, as there are many BSD-isms in the source code
# that we don't want to bother to patch out.  Things like err.h and whatnot.
platforms = filter(!Sys.iswindows, supported_platforms())

# The products that we will ensure are always built
products = [
    ExecutableProduct("bspatch", :bspatch),
    ExecutableProduct("bsdiff", :bsdiff)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Bzip2_jll"; compat="1.0.8"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
