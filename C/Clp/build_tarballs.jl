using BinaryBuilder

name = "ClpBuilder"
version = v"1.16.11"

# Collection of sources required to build ClpBuilder
sources = [
    GitSource("https://github.com/coin-or/Clp.git",
    "aae123d7a3c633a382b7cb9c1f4f78ed6559a10b"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Clp*
update_configure_scripts

# Fix some paths
for path in ${LD_LIBRARY_PATH//:/ }; do
    for file in $(ls $path/*.la); do
        echo "$file"
        baddir=$(sed -n "s|libdir=||p" $file)
        sed -i~ -e "s|$baddir|'$path'|g" $file
    done
done


mkdir build
cd build/

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} --enable-shared \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-lasl" --with-asl-incdir="$prefix/include" \
--with-blas="-lopenblas" --with-lapack="-openblas" \
--with-metis-lib="-lmetis" --with-metis-incdir="$prefix/include" \
--without-mumps \
--with-coinutils-lib="-lCoinUtils" --with-coinutils-incdir="$prefix/include/coin" \
--with-osi-lib="-lOsi" --with-osi-incdir="$prefix/include/coin"

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = supported_platforms()
platforms = [p for p in platforms if !(typeof(p) <: FreeBSD)]
platforms = [p for p in platforms if !(arch(p) == :powerpc64le)]

# The products that we will ensure are always built
products = [
    LibraryProduct("libOsiClp", :libOsiClp),
    LibraryProduct("libClp", :libClp),
    LibraryProduct("libClpSolver", :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CoinUtils_jll"),
    Dependency("Osi_jll"),
    Dependency("ASL_jll"),
    Dependency("METIS_jll@4"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
