using BinaryBuilder, Pkg

name = "Clp"
version = v"1.17.3"

# Collection of sources required to build Clp
sources = [
    GitSource("https://github.com/coin-or/Clp.git", 
    "29a3d29d94f102e9029eb4be72cde2bfd378d752"), 
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Clp*

# Remove misleading libtool files                                                                                            
rm -f ${prefix}/lib/*.la                                                                                                     
rm -f /opt/${target}/${target}/lib*/*.la                                                                                     
update_configure_scripts

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I$prefix/include/coin"
export CXXFLAGS="${CXXFLAGS} -std=c++11"
if [[ ${target} == *mingw* ]]; then	
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-asl-lib="-lasl" \
--with-blas="-lopenblas" --with-lapack="-openblas" \
--with-metis-lib="-lmetis" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" 

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
    LibraryProduct("libClp", :libClp),
    LibraryProduct("libOsiClp", :libOsiClp),
    LibraryProduct("libClpSolver", :libClpSolver)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(; name = "CoinUtils_jll", uuid = "be027038-0da8-5614-b30d-e42594cb92df", version = v"2.11.3")),
    Dependency(PackageSpec(; name = "Osi_jll", uuid = "7da25872-d9ce-5375-a4d3-7a845f58efdd", version = v"0.108.5")),
    Dependency(PackageSpec(; name = "METIS_jll", uuid = "d00139f3-1899-568f-a2f0-47f597d42d70", version = v"4.0.3")),
    Dependency("ASL_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
