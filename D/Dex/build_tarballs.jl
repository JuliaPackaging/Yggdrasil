# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Dex"
version = v"2.23.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dexidp/dex.git", "d820fd45d80cef74d4c65f5fcc5766ddb1fa514e"),
    DirectorySource("bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p "${bindir}"
cd dex/
atomic_patch -p1 ../patches/01-allow-optional-github-gitlab-scopes.patch
install_license LICENSE 
make
mv bin/dex "$bindir/dex${exeext}"
mv bin/example-app "$bindir/example-app${exeext}"
mv bin/grpc-client "$bindir/grpc-client${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:musl),
    Linux(:x86_64, libc=:glibc)
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("example-app", :exampleapp),
    ExecutableProduct("grpc-client", :grpcclient),
    ExecutableProduct("dex", :dex)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers = [:go, :c])
