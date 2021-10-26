# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ViennaRNA"
version = v"2.4.18"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ViennaRNA/ViennaRNA/releases/download/v$(version)/ViennaRNA-$(version).tar.gz",
                  "b276cfed7c3bea4821c8272750b5b22fa6fed614d71a98cfb25eb0095369657c")
]

# Bash recipe for building across all platforms
# Notes:
# - openmp not supported on darwin
# - libsvm is included in the ViennaRNA sources, and it's not
#   immediately obvious how to make the build script use libsvm_jll
# --with-forester fails to compile on windows
#     In file included from aligner.cpp:3:
#     aligner.h:21:10: fatal error: sys/times.h: No such file or directory
script = raw"""
cd $WORKSPACE/srcdir
cd ViennaRNA-*/

# configure script needs bash
sed -i -e '1s|#! /bin/sh|#! /bin/bash|' configure

# set this explicitly for the libsvm Makefile, which would
# otherwise use g++
export CC=cc
export CXX=c++

# help freebsd find include files for mpfr, gsl
export CPPFLAGS="-I${includedir}"

# configure script fails (only in sandbox) without
# setting ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    ./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic --disable-c11 \
    --with-mpfr --with-json --with-svm --with-gsl \
    --without-forester --with-cluster --with-kinwalker \
    --without-perl --without-python --without-python3 \
    --without-doc --without-tutorial --without-tutorial-pdf

make -j${nproc}
make install

# create and install a shared library libRNA
ldflags="-g -O2 -fno-strict-aliasing -ftree-vectorize -pthread"
# add for gcc (linux,windows): -flto -ffat-lto-objects
# TODO: how to check if compiler is gcc/g++ ?
if [[ $target != *-darwin* ]]; then
    ldflags="$ldflags -fopenmp"
fi
ldflags_libs="-lpthread -lmpfr -lgmp -lstdc++ -lgsl -lgslcblas -lm"
$CC -shared -o "${libdir}/libRNA.${dlext}" \
    $ldflags \
    -Wl,$(flagon --whole-archive) ./src/ViennaRNA/libRNA.a -Wl,$(flagon --no-whole-archive) \
    $ldflags_libs

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
# remedy for std::string incompatibilities across the GCC 4/5 version boundary
# (suggested by BinaryBuilder)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("AnalyseDists", :AnalyseDists),
    ExecutableProduct("AnalyseSeqs", :AnalyseSeqs),
    ExecutableProduct("b2ct", :b2ct),
    ExecutableProduct("ct2db", :ct2db),
    ExecutableProduct("Kinfold", :Kinfold),
    ExecutableProduct("kinwalker", :Kinfold),
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
    # enable with --with-forester
    # ExecutableProduct("RNAforester", :RNAforester),
    ExecutableProduct("RNAheat", :RNAheat),
    ExecutableProduct("RNAinverse", :RNAinverse),
    ExecutableProduct("RNALalifold", :RNALalifold),
    ExecutableProduct("RNALfold", :RNALfold),
    ExecutableProduct("RNAlocmin", :RNAlocmin),
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
# CompilerSupportLibraries_jll suggested by BinaryBuilder for OpenMP support
dependencies = [
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"11")
