# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, BinaryBuilderBase

name = "strace"
version = v"6.7.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/strace/strace.git",
              "091ed4fda1f8ab86b79b52790d4ebc41c333bc49"),
]

# Adapted from the justfile of the repo
script = raw"""
cd $WORKSPACE/srcdir/strace

# Install GNU date so that bootstrap works
cp ${host_bindir}/date /usr/local/bin/
./bootstrap

# Disable multiple personalities as our 64-bit compilers do not have 32-bit capabilities
# Disable -Werror
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
            --enable-mpers=no \
            --disable-gcc-Werror
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = filter(p -> Sys.islinux(p), supported_platforms())
platforms = filter(p -> !(libc(p) == "musl" && arch(p) == "aarch64"), platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("strace", :strace),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # strace build requires GNU `date`
    HostBuildDependency("coreutils_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", compilers=[:c])
