using BinaryBuilder

# Collection of sources required to build Nettle
name = "ntl"
version = v"10.5.0"
sources = [
    "https://www.shoup.net/ntl/ntl-10.5.0.tar.gz" =>
    "b90b36c9dd8954c9bc54410b1d57c00be956ae1db5a062945822bbd7a86ab4d2",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ntl-*/src
./configure "PREFIX=${prefix}" "GMP_PREFIX=${prefix}" NATIVE=off SHARED=on TUNE=x86 CXX="ccache ${CXX}"
make -j${nproc}
make install
"""

# Bootstrapping problem; only do natively-runnable platforms
platforms = [
    Linux(:x86_64),
    Linux(:i686),
    Linux(:x86_64; libc=:musl),
]

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libntl", :libntl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
