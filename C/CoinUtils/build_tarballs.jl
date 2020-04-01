using BinaryBuilder

name = "CoinUtils"
version = v"2.10.14"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git", "f01efb018b4c8300634f268e8029f5414208f05c"),
#    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils*

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib*/*.la

CPPFLAGS="-I${prefix}/include"
update_configure_scripts
./configure --prefix=${prefix} --host=${target} --with-blas --with-blas-lib="-lopenblas" --with-lapack --with-lapack-lib="-lopenblas"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#platforms = expand_cxxstring_abis(supported_platforms())
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
#    Dependency("GLPK_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
