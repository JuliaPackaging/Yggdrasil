# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "NUMA"
version = v"2.0.19"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/numactl/numactl/releases/download/v$(version)/numactl-$(version).tar.gz",
                  "f2672a0381cb59196e9c246bf8bcc43d5568bc457700a697f1a1df762b9af884"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
# Add the `set_mempolicy_home_node` syscall number for the architectures upstream doesn't list
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
