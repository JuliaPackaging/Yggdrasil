using BinaryBuilder, Pkg

name = "Cgl"
version = v"0.60.2"

# Collection of sources required to build Cgl
sources = [
   GitSource("https://github.com/coin-or/Cgl.git",
             "6377b88754fafacf24baac28bb27c0623cc14457"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cgl*

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
   LibraryProduct("libCgl", :libCgl),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(; name = "Clp_jll", uuid = "06985876-5285-5a41-9fcb-8948a742cc53", version = v"1.17.3")),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
