using BinaryBuilder, Pkg

name = "Osi"
version = v"0.108.5"

# Collection of sources required to build OsiBuilder
sources = [
    GitSource("https://github.com/coin-or/Osi.git",
              "2bd34ae6b8c93d342d54fd19d4d773f07194583c")
]

script = raw"""
cd $WORKSPACE/srcdir/Osi*

# Remove misleading libtool files                                                                                            
rm -f ${prefix}/lib/*.la                                                                                                     
rm -f /opt/${target}/${target}/lib*/*.la                                                                                     
update_configure_scripts

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I${prefix}/include/coin"                                                   
export CXXFLAGS="${CXXFLAGS} -std=c++11"                                                                                     
if [[ ${target} == *mingw* ]]; then	
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-lCoinUtils" \
--with-blas-lib="-lopenblas" --with-lapack-lib="-lopenblas"

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
    LibraryProduct("libOsiCommonTests", :libOsiCommonTests),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(; name = "CoinUtils_jll", uuid = "be027038-0da8-5614-b30d-e42594cb92df", version = v"2.11.3")),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
