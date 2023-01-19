# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "protoc"
version = v"3.21.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/protocolbuffers/protobuf.git", "c9869dc7803eb0a21d7e589c40ff4f9288cd34ae"),
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
    LibraryProduct("libprotobuf", :libprotobuf),
    ExecutableProduct("protoc", :protoc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"9", julia_compat="1.6")
