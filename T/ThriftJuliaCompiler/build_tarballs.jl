# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ThriftJuliaCompiler"
version = v"0.12.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/tanmaykm/thrift.git", "5fa011a2b55a5fdffaa5b5674772b18c82b8a320")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd thrift/
./bootstrap.sh 
if [ $target != "x86_64-apple-darwin14" ] && [ $target != "x86_64-unknown-freebsd11.1" ]; then LDFLAGS="-static-libgcc -static-libstdc++"; export LDFLAGS; fi
./configure --prefix=$prefix --build=${MACHTYPE} --host=$target --enable-tutorial=no --enable-tests=no --enable-libs=no --disable-werror
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("thrift", :thrift)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
