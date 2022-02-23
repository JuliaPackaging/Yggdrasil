# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protoc"
version = v"3.19.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "22d0e265de7d2b3d2e9a00d071313502e7d4cccf"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/protobuf
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libprotoc", :libprotoc),
    ExecutableProduct("protoc", :protoc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"9", julia_compat="1.6")
