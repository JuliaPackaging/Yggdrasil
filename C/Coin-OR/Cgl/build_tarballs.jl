include("../coin-or-common.jl")

name = "Cgl"
version = Cgl_version

# Collection of sources required to build Cgl
sources = [
   GitSource("https://github.com/coin-or/Cgl.git",
             Cgl_gitsha),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/Cgl*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
update_configure_scripts

# old and custom autoconf
sed -i s/elf64ppc/elf64lppc/ configure

mkdir build
cd build/

export CPPFLAGS="${CPPFLAGS} -DNDEBUG -I${prefix}/include -I$prefix/include/coin"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

../configure --prefix=$prefix --build=${MACHTYPE} --host=${target} \
--with-pic --disable-pkg-config --disable-debug \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-osiclp-lib="-lOsiClp -lClp -lOsi -lCoinUtils"

make -j${nproc}
make install
"""

# The products that we will ensure are always built
products = [
   LibraryProduct("libCgl", :libCgl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(Clp_packagespec),
    Dependency("CompilerSupportLibraries_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=gcc_version)
