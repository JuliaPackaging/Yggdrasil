using BinaryBuilder, Pkg

name = "Cgl"
version = v"0.59.10"

# Collection of sources required to build Cgl
sources = [
   GitSource("https://github.com/coin-or/Cgl.git",
             "8152008bfe6bc84e9d46a43472734d40dd79dbb2"),

]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cgl*
update_configure_scripts

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la

mkdir build
cd build/

export CPPFLAGS="-I${prefix}/include -I${prefix}/include/coin"
export CXXFLAGS="-std=c++11"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --with-pic --disable-pkg-config --build=${MACHTYPE} --host=${target} --enable-shared \
--enable-dependency-linking lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-osiclp-lib="-lOsiClp -lClp -lOsi -lCoinUtils"

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
   LibraryProduct(["libCgl", "libCgl-1"], :libCgl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("Clp_jll"),
    Dependency("Osi_jll"),
    Dependency("CoinUtils_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
