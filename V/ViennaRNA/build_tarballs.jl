# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ViennaRNA"
version = v"2.5.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ViennaRNA/ViennaRNA/releases/download/v$(version)/ViennaRNA-$(version).tar.gz",
                  "be4414d574825ef7236533e2885b2bd795f6e833487236ad1ff45cdd4b7e44b7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
# Build issues
# - powerpc64le: build fails in vectorisation routines of dlib
script = raw"""
cd $WORKSPACE/srcdir/ViennaRNA-*/

# configure script needs bash
sed -i -e '1s|#! /bin/sh|#! /bin/bash|' configure

# set this explicitly for the libsvm Makefile, which would
# otherwise use g++
export CC=cc
export CXX=c++

# where to find dependencies
export CPPFLAGS="-I${includedir}"
export LDFLAGS="-L${libdir}"

if [[ $target == *-w64-mingw32* ]]; then
    # time measurement in RNAforester doesn't compile on windows (mingw32),
    # so we disable it
    atomic_patch -p1 ../patches/windows-forester-remove-time-measurement.patch

    # needed for compilation of dlib on windows
    export LIBS="-lwinmm"

    # fix for missing nonstandard strcasestr function on windows
    atomic_patch -p1 ../patches/windows-strcasestr-fix.patch
fi

# configure script fails (only in sandbox) without
# setting ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    ./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic --disable-c11 \
    --with-mpfr --with-json --with-svm --with-gsl \
    --enable-openmp \
    --with-cluster --with-kinwalker \
    --without-perl --without-python --without-python3 \
    --without-doc --without-tutorial --without-cla

make -j${nproc}
make install

# create and install a shared library libRNA
ldflags="$LDFLAGS -g -O2 -fno-strict-aliasing -ftree-vectorize -pthread -fopenmp"
libs="-lpthread -lmpfr -lgmp -lstdc++ -lgsl -lgslcblas -lm $LIBS"

# TODO: setting -flto -ffat-lto-objects assumes we are using gcc
if [[ $target == *-linux-* ]]; then
    ldflags="$ldflags -flto -ffat-lto-objects"
elif [[ $target == *-w64-mingw32* ]]; then
    ldflags="$ldflags -flto -ffat-lto-objects"
    # needed for dlib
    libs="$libs -lws2_32"
fi

$CC -shared -o "${libdir}/libRNA.${dlext}" \
    $ldflags \
    -Wl,$(flagon --whole-archive) ./src/ViennaRNA/libRNA.a -Wl,$(flagon --no-whole-archive) \
    $libs

cp src/cthreadpool/LICENSE LICENSE-cthreadpool
cp src/dlib-*/LICENSE.txt LICENSE-dlib
cp src/json/LICENSE LICENSE-json
cp src/libsvm-*/COPYRIGHT COPYRIGHT-libsvm
cp src/RNAforester/COPYING COPYING-RNAforester
install_license LICENSE-cthreadpool
install_license LICENSE-dlib
install_license LICENSE-json
install_license COPYRIGHT-libsvm
install_license COPYING-RNAforester
install_license COPYING
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true, exclude = p -> arch(p) == "powerpc64le")
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
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
    LibraryProduct("libRNA", :libRNA),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3")),
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"); compat="~2.7.2"),
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else.
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"7")
