using BinaryBuilder

# Collection of sources required to build Nettle
name = "ntl"
version = v"11.4.3"
sources = [
    ArchiveSource("https://www.shoup.net/ntl/ntl-$(version).tar.gz",
                  "b7c1ccdc64840e6a24351eb4a1e68887d29974f03073a1941c906562c0b83ad2"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ntl-*/src
./configure PREFIX="${prefix}" GMP_PREFIX="${prefix}" NATIVE=off SHARED=on

make -j${nproc}
make install

install_license ../doc/copying.txt
"""

# Bootstrapping problem; only do natively-runnable platforms
platforms = [
    Platform("x86_64", "linux"),
    Platform("i686", "linux"),
    Platform("x86_64", "linux"; libc="musl"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libntl", :libntl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.1.2"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
