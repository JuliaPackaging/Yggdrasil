include("../coin-or-common.jl")

name = "SDPA"
version = v"7.3.8"

# Collection of sources required to build SDPABuilder
sources = [
    ArchiveSource("https://sourceforge.net/projects/sdpa/files/sdpa/sdpa_$(version).tar.gz",
                  "c7541333da2f0bb2d18e90dbf758ac7cc099f3f7da3f256b284b0725f96d4117")
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/sdpa-*

# Remove misleading libtool files
rm -f ${prefix}/lib/*.la
rm -f /opt/${target}/${target}/lib*/*.la
update_configure_scripts

# Apply patches
atomic_patch -p1 $WORKSPACE/srcdir/patches/shared.diff
mv configure.in configure.ac
atomic_patch -p1 $WORKSPACE/srcdir/patches/lt_init.diff
autoreconf -vi

export CPPFLAGS="${CPPFLAGS} -I${prefix}/include -I$prefix/include/coin"
export CXXFLAGS="${CXXFLAGS} -std=c++11"
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L$prefix/bin"
elif [[ ${target} == *linux* ]]; then
    export LDFLAGS="-ldl -lrt"
fi

./configure --prefix=$prefix --with-pic --disable-pkg-config  --build=${MACHTYPE} --host=${target} \
--enable-shared lt_cv_deplibs_check_method=pass_all \
--with-blas="-lopenblas" --with-lapack="-openblas" \
--with-coinutils-lib="-lCoinUtils" \
--with-osi-lib="-lOsi -lCoinUtils" \
--with-mumps-lib="-L${prefix}/lib -ldmumps -lzmumps -lcmumps -lsmumps -lmumps_common -lmpiseq -lpord -lmetis -lopenblas -lgfortran -lpthread" \
--with-mumps-incdir="${prefix}/include/mumps_seq" \
--with-metis-lib="-L${prefix}/lib -lmetis" --with-metis-incdir="${prefix}/include"



make -j${nproc}
make install

## Then build the libcxxwrap-julia wrapper
cd $WORKSPACE/srcdir/sdpawrap

mkdir build
cd build/

if [[ $target == i686-* ]] || [[ $target == arm-* ]]; then
    export processor=pentium4
else
    export processor=x86-64
fi

cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DSDPA_DIR=$prefix \
      -DCMAKE_FIND_ROOT_PATH=${prefix} \
      -DJulia_PREFIX=${prefix} \
      -DSDPA_LIBRARY="-lsdpa" \
      -DCMAKE_CXX_FLAGS="-march=$processor" \
      -D_GLIBCXX_USE_CXX11_ABI=1 \
      -DJlCxx_DIR=$prefix/lib/cmake/JlCxx \
      ..
cmake --build . --config Release --target install

if [[ $target == *w64-mingw32* ]] ; then
    cp $WORKSPACE/destdir/lib/libsdpawrap.dll ${libdir}
fi
"""

# The products that we will ensure are always built
products = [
    ExecutableProduct("sdpa", :sdpa),
    LibraryProduct("libsdpa", :libsdpa),
    LibraryProduct("libsdpawrap", :libsdpawrap)
]

# Pick platforms from L/libcxxwrap-julia/build_tarballs.jl
platforms = [
    FreeBSD(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:armv7l; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:aarch64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:i686; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Windows(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Windows(:i686; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libcxxwrap_julia_jll"),
    Dependency("OpenBLAS32_jll"),
    Dependency("CompilerSupportLibraries_jll"),
    BuildDependency(MUMPS_seq_packagespec),
    BuildDependency(METIS_packagespec),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"7")
