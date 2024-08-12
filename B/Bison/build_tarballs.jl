# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Bison"
version = v"3.8.2"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/bison/bison-$(version).tar.xz", "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bison-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-relocatable
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = [
    ExecutableProduct("bison", :bison)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    # We don't, strictly speaking, need `Libiconv_jll` on linux because it's included in glibc
    Dependency("Libiconv_jll"; platforms=filter(!Sys.islinux, platforms)),
]

# We require `gcc` v5+ to avoid the following error on some systems:
# Inconsistency detected by ld.so: dl-version.c: 204: _dl_check_map_versions: Assertion `needed != NULL' failed!
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
