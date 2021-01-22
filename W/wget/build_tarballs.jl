# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "wget"
version = v"1.20.3"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/wget/wget-$(version).tar.gz",
                  "31cccfc6630528db1c8e3a06f6decf2a370060b982841cfab2b8677400a5092e")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/wget-*/
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# Disable windows because GnuTLS_jll is not available there
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("wget", :wget)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GnuTLS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
