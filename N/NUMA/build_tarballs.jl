# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NUMA"
version = v"2.0.18"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/numactl/numactl/releases/download/v$(version)/numactl-$(version).tar.gz",
                  "b4fc0956317680579992d7815bc43d0538960dc73aa1dd8ca7e3806e30bc1274"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
# Patch taken from master branch, with <https://github.com/numactl/numactl/issues/219> added
cd numactl*
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/home_node.patch
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
