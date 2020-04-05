using BinaryBuilder, Pkg

name = "Cbc"
version = v"2.10.3"

# Collection of sources required to build CbcBuilder
sources = [
    GitSource("https://github.com/coin-or/Cbc.git",
               "6fe3addaa76436d479d4431add67b371e11d3e83"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cbc*
update_configure_scripts

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

# Apply patch related to https://github.com/JuliaOpt/Cbc.jl/issues/117 and https://github.com/coin-or/Cbc/issues/267
(cd Cbc/src && atomic_patch -p0 $WORKSPACE/srcdir/patches/no_lp.patch)

mkdir build
cd build/

export CPPFLAGS="-I${prefix}/include -I${prefix}/include/coin"
export CXXFLAGS="-std=c++11"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config  --build=${MACHTYPE} --host=${target} --enable-shared --disable-static \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas-lib="-lopenblas" --with-lapack-lib="-lopenblas" \
--with-metis-lib="-lmetis" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-clp-lib="-lClp -lOsiClp -lCoinUtils" \
--with-cgl-lib="-lCgl -lClp -lOsiClp -lOsic -lCoinUtils" \
--with-coindepend-lib="-lCgl -lOsi -lClp -lOsiClp -lmetis -lcoinUtils -lgfortran" \
--enable-cbc-parallel

make -j${nproc}

# Clean-up bin directory before installing
rm -f ${prefix}/bin/*

# Install
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]


# The products that we will ensure are always built
products = [
    LibraryProduct(["libCbc", "libCbc-1"], :libCbc),
    LibraryProduct(["libCbcSolver", "libCbcSolver-1"], :libcbcsolver),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Clp_jll"),
    Dependency("Cgl_jll"),
    Dependency("Osi_jll"),
    Dependency("CoinUtils_jll"),
    Dependency(PackageSpec(; name = "METIS_jll", uuid = "d00139f3-1899-568f-a2f0-47f597d42d70", version = v"4.0.3")),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),

]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
