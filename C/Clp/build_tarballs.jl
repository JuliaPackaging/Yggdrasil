using BinaryBuilder, Pkg

name = "ClpBuilder"
version = v"1.16.11"

# Collection of sources required to build ClpBuilder
sources = [
    GitSource("https://github.com/coin-or/Clp.git", 
    "aae123d7a3c633a382b7cb9c1f4f78ed6559a10b"), # 1.16.11
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Clp*
update_configure_scripts

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

mkdir build
cd build/

export CPPFLAGS="-I${prefix}/include"
if [[ ${target} == *mingw* ]]; then	
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} --enable-shared \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-lasl" --with-asl-incdir="$prefix/include" \
--with-blas="-lopenblas" --with-lapack="-openblas" \
--with-metis-lib="-lmetis" --with-metis-incdir="$prefix/include" \
--with-coinutils-lib="-lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-lOsi -lCoinUtils" --with-osi-incdir="$prefix/include/coin"

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
    LibraryProduct(["libClp", "libClp-1"], :libClp),
    LibraryProduct(["libOsiClp", "libOsiClp-1"], :libOsiClp),
    LibraryProduct(["libClpSolver", "libClpSolver-1"], :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CoinUtils_jll"),
    Dependency("Osi_jll"),
    Dependency("ASL_jll"),
    Dependency(PackageSpec(; name = "METIS_jll", uuid = "d00139f3-1899-568f-a2f0-47f597d42d70", version = v"4.0.3")),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
