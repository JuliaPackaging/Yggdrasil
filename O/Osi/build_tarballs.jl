using BinaryBuilder

name = "OsiBuilder"
version = v"0.107.9"

# Collection of sources required to build OsiBuilder
sources = [
    GitSource("https://github.com/coin-or/Osi.git",
              "60255835a0930e9a15247bd6ae496c930c2d3878")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Osi*
update_configure_scripts

mkdir build
cd build/

export CXXFLAGS="-std=c++11"

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} --enable-shared --enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-blas-lib="-lopenblass" --with-lapack-lib="-lopenblas"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libOsi", :libOsi),
    LibraryProduct("libOsiCommonTests", :libOsiCommonTests)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CoinUtils_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
