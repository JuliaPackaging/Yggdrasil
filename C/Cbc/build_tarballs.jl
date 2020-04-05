using BinaryBuilder, Pkg

name = "Cbc"
version = v"2.10.5"

# Collection of sources required to build CbcBuilder
sources = [
    GitSource("https://github.com/coin-or/Cbc.git",
               "7b5ccc016f035f56614c8018b20d700978144e9f"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cbc*
update_configure_scripts

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la

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

../configure --prefix=$prefix --with-pic --disable-pkg-config  --build=${MACHTYPE} --host=${target} --enable-shared \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-lasl" --with-asl-incdir="$prefix/include/asl" \
--with-blas-lib="-lopenblas" --with-lapack-lib="-lopenblas" \
--with-metis-lib="-lmetis" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-clp-lib="-lClp -lOsiClp -lCoinUtils" \
--with-cgl-lib="-lCgl -lClp -lOsiClp -lOsi -lCoinUtils" 

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
    LibraryProduct("libCbc", :libCbc),
    LibraryProduct("libCbcSolver", :libcbcsolver),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(; name = "Clp_jll", uuid = "06985876-5285-5a41-9fcb-8948a742cc53", version = v"1.17.5")),
    Dependency(PackageSpec(; name = "Cgl_jll", uuid = "3830e938-1dd0-5f3e-8b8e-b3ee43226782", version = v"0.60.3")),
    Dependency(PackageSpec(; name = "Osi_jll", uuid = "7da25872-d9ce-5375-a4d3-7a845f58efdd", version = v"0.108.6")),
    Dependency(PackageSpec(; name = "CoinUtils_jll", uuid = "be027038-0da8-5614-b30d-e42594cb92df", version = v"2.11.4")),
    Dependency(PackageSpec(; name = "METIS_jll", uuid = "d00139f3-1899-568f-a2f0-47f597d42d70", version = v"4.0.3")),
    Dependency("ASL_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
