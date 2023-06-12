using BinaryBuilder, Pkg

name = "ViennaRNA"
version = v"2.6.1"

sources = [
    ArchiveSource("https://www.tbi.univie.ac.at/RNA/download/sourcecode/" *
                  "$(version.major)_$(version.minor)_x/ViennaRNA-$(version).tar.gz",
                  "f778876bbe8e6c85725a633819b26468307c919635e82b278ba820eff8badf76"),
    DirectorySource("./bundled")
]

# Build issues
# - powerpc64le: build fails in vectorisation routines of dlib
# - windows and gcc-8: internal compiler error during lto on gcc-8,
#   which is why we use gcc-9

# Notes
# - I think only RNAxplorer needs to link to blas, lapack (and pcre on windows)
#   also the generated shared lib doesn't need to link to these libs


script = raw"""
cd $WORKSPACE/srcdir/ViennaRNA*/

# configure script needs /bin/bash
sed -i -e '1s|#! /bin/sh|#! /bin/bash|' configure

# set this explicitly for the libsvm Makefile, which would
# otherwise always use g++
export CC=cc
export CXX=c++

# where to find dependencies
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

if [[ "${target}" == *-w64-mingw32* ]]; then
    # time measurement in RNAforester doesn't compile on windows (mingw32),
    # so we disable it
    atomic_patch -p1 ../patches/windows-forester-remove-time-measurement.patch

    # fix for missing nonstandard strcasestr function on windows
    atomic_patch -p1 ../patches/windows-strcasestr-fix.patch

    # fix for missing sysconf on windows
    atomic_patch -p1 ../patches/RNAxplorer-windows-fix-missing-sysconf.patch

    # fix for missing getline on windows, we use the one from NetBSD
    atomic_patch -p1 ../patches/RNAxplorer-windows-fix-missing-getline.patch

    # needed for compilation of dlib on windows
    export LIBS="-lwinmm"

    # work around there not being a regex.h on w64-mingw32
    cp "${includedir}/pcreposix.h" "${includedir}/regex.h"
    export LIBS="$LIBS -lpcreposix-0"

    # BLAS/LAPACK support
    export LIBS="$LIBS -lblastrampoline-5"
else
    # BLAS/LAPACK support
    export LIBS="$LIBS -lblastrampoline"
fi


# configure script fails (only in sandbox) without
# setting ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    ./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic --disable-c11 \
    --with-mpfr --with-json --with-svm --with-gsl \
    --enable-openmp \
    --with-rnaxplorer --with-blas="${libdir}/libopenblas.${dlext}" --with-lapack="${libdir}/liblapack.${dlext}" \
    --with-cluster --with-kinwalker \
    --without-perl --without-python --without-python2 \
    --without-doc --without-tutorial --without-cla

make -j${nproc}
make install

if [[ "${target}" == *-w64-mingw32* ]]; then
    # remove PCRE regex.h so it doesn't get included in the jll package
    rm "${includedir}/regex.h"
fi

# create and install a shared library libRNA
ldflags="$LDFLAGS -g -O2 -fno-strict-aliasing -ftree-vectorize -pthread -fopenmp"
libs="-lpthread -lmpfr -lgmp -lstdc++ -lgsl -lgslcblas -lm $LIBS"

# Note: setting -flto=auto -ffat-lto-objects assumes we are using gcc
if [[ "${target}" == *-linux-* ]]; then
    ldflags="$ldflags -flto=auto -ffat-lto-objects"
elif [[ "${target}" == *-w64-mingw32* ]]; then
    ldflags="$ldflags -flto=auto -ffat-lto-objects"
    # needed for dlib
    libs="$libs -lws2_32"
fi

"${CC}" \
    -shared -o "${libdir}/libRNA.${dlext}" \
    $ldflags \
    -Wl,$(flagon --whole-archive) ./src/ViennaRNA/libRNA.a -Wl,$(flagon --no-whole-archive) \
    $libs

# install licenses
cp src/cthreadpool/LICENSE LICENSE-cthreadpool
cp src/dlib-*/LICENSE.txt LICENSE-dlib
cp src/json/LICENSE LICENSE-json
cp src/libsvm-*/COPYRIGHT COPYRIGHT-libsvm
cp src/RNAforester/COPYING COPYING-RNAforester
cp src/RNAxplorer/COPYING COPYING-RNAxplorer
install_license LICENSE-cthreadpool
install_license LICENSE-dlib
install_license LICENSE-json
install_license COPYRIGHT-libsvm
install_license COPYING-RNAforester
install_license COPYING-RNAxplorer
install_license COPYING
if [[ "${target}" == *-w64-mingw32* ]]; then
    # this code/license is only added on windows via a patch
    cp src/RNAxplorer/COPYING-getline COPYING-RNAxplorer-getline
    install_license COPYING-RNAxplorer-getline
fi
"""

platforms = supported_platforms(; exclude = p -> arch(p) == "powerpc64le")
platforms = expand_cxxstring_abis(platforms)

products = [
    ExecutableProduct("AnalyseDists", :AnalyseDists),
    ExecutableProduct("AnalyseSeqs", :AnalyseSeqs),
    ExecutableProduct("b2ct", :b2ct),
    ExecutableProduct("ct2db", :ct2db),
    ExecutableProduct("Kinfold", :Kinfold),
    ExecutableProduct("kinwalker", :kinwalker),
    ExecutableProduct("popt", :popt),
    ExecutableProduct("RNA2Dfold", :RNA2Dfold),
    ExecutableProduct("RNAaliduplex", :RNAaliduplex),
    ExecutableProduct("RNAalifold", :RNAalifold),
    ExecutableProduct("RNAcofold", :RNAcofold),
    ExecutableProduct("RNAdistance", :RNAdistance),
    ExecutableProduct("RNAdos", :RNAdos),
    ExecutableProduct("RNAduplex", :RNAduplex),
    ExecutableProduct("RNAeval", :RNAeval),
    ExecutableProduct("RNAfold", :RNAfold),
    ExecutableProduct("RNAforester", :RNAforester),
    ExecutableProduct("RNAheat", :RNAheat),
    ExecutableProduct("RNAinverse", :RNAinverse),
    ExecutableProduct("RNALalifold", :RNALalifold),
    ExecutableProduct("RNALfold", :RNALfold),
    ExecutableProduct("RNAlocmin", :RNAlocmin),
    ExecutableProduct("RNAmultifold", :RNAmultifold),
    ExecutableProduct("RNApaln", :RNApaln),
    ExecutableProduct("RNAparconv", :RNAparconv),
    ExecutableProduct("RNApdist", :RNApdist),
    ExecutableProduct("RNAPKplex", :RNAPKplex),
    ExecutableProduct("RNAplex", :RNAplex),
    ExecutableProduct("RNAplfold", :RNAplfold),
    ExecutableProduct("RNAplot", :RNAplot),
    ExecutableProduct("RNApvmin", :RNApvmin),
    ExecutableProduct("RNAsnoop", :RNAsnoop),
    ExecutableProduct("RNAsubopt", :RNAsubopt),
    ExecutableProduct("RNAup", :RNAup),
    ExecutableProduct("RNAxplorer", :RNAxplorer),
    LibraryProduct("libRNA", :libRNA),
]

dependencies = [
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3")),
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    # we need BLAS/LAPACK for RNAxplorer
    Dependency("LAPACK_jll"),
    Dependency("OpenBLAS_jll"),
    # windows POSIX regex replacement via PCRE
    Dependency("PCRE_jll"; platforms=filter(Sys.iswindows, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"9")
