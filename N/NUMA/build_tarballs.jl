# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NUMA"
version = v"2.0.14"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/numactl/numactl/releases/download/v$(version)/numactl-$(version).tar.gz",
                  "826bd148c1b6231e1284e42a4db510207747484b112aee25ed6b1078756bcff6"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd numactl-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc} numademo_CFLAGS="-O3 -funroll-loops"
make install
install_license LICENSE.*
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=!Sys.islinux)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnuma", :libnuma),
    ExecutableProduct("numactl", :numactl),
    ExecutableProduct("numastat", :numastat)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
