# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ViennaRNA"
version = v"2.4.18"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/ViennaRNA/ViennaRNA/releases/download/v2.4.18/ViennaRNA-2.4.18.tar.gz",
                  "b276cfed7c3bea4821c8272750b5b22fa6fed614d71a98cfb25eb0095369657c")
]

# Bash recipe for building across all platforms
# Notes:
# - linking problems when using (built-in or JLL pkg) SVM (libsvm) on non-linux targets
# - compilation problems when using GSL on non-linux targets
script = raw"""
cd $WORKSPACE/srcdir
cd ViennaRNA-2.4.18/

# configure script needs bash
sed -i -e '1s|#! /bin/sh|#! /bin/bash|' configure

# configure script fails (only in sandbox) without
# setting ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    ./configure \
    --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic --disable-c11 \
    --without-perl --without-python --without-python3 \
    --without-doc --without-tutorial --without-tutorial-pdf \
    --without-gsl --without-svm \
    --without-forester

make -j${nproc}
make install

# create and install a shared library libRNA
#cc -shared -o "${libdir}/libRNA.${dlext}" -Wl,$(flagon --whole-archive) ./src/ViennaRNA/libRNA.a -Wl,$(flagon --no-whole-archive) -lgsl -lgslcblas -lm -lsvm -lgomp -lgsl -lmpfr
cc -shared -o "${libdir}/libRNA.${dlext}" -Wl,$(flagon --whole-archive) ./src/ViennaRNA/libRNA.a -Wl,$(flagon --no-whole-archive) -lm -lgomp -lmpfr
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
# remedy for std::string incompatibilities across the GCC 4/5 version boundary
# (suggested by BinaryBuilder)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("RNAPKplex", :RNAPKplex),
    ExecutableProduct("RNAlocmin", :RNAlocmin),
    ExecutableProduct("RNAplex", :RNAplex),
    ExecutableProduct("RNAeval", :RNAeval),
    ExecutableProduct("RNAsnoop", :RNAsnoop),
    ExecutableProduct("ct2db", :ct2db),
    ExecutableProduct("RNAcofold", :RNAcofold),
    ExecutableProduct("RNApaln", :RNApaln),
    LibraryProduct("libRNA", :libRNA),
    ExecutableProduct("Kinfold", :Kinfold),
    ExecutableProduct("RNApdist", :RNApdist),
    ExecutableProduct("RNAplot", :RNAplot),
    ExecutableProduct("RNApvmin", :RNApvmin),
    ExecutableProduct("RNAaliduplex", :RNAaliduplex),
    ExecutableProduct("RNAduplex", :RNAduplex),
    ExecutableProduct("RNAdistance", :RNAdistance),
    ExecutableProduct("RNAheat", :RNAheat),
    ExecutableProduct("RNALalifold", :RNALalifold),
    ExecutableProduct("popt", :popt),
    ExecutableProduct("RNAalifold", :RNAalifold),
    ExecutableProduct("RNAsubopt", :RNAsubopt),
    ExecutableProduct("RNALfold", :RNALfold),
    ExecutableProduct("RNAfold", :RNAfold),
    ExecutableProduct("RNAinverse", :RNAinverse),
    ExecutableProduct("RNA2Dfold", :RNA2Dfold),
    ExecutableProduct("RNAdos", :RNAdos),
    ExecutableProduct("RNAparconv", :RNAparconv),
    ExecutableProduct("RNAplfold", :RNAplfold),
    ExecutableProduct("RNAup", :RNAup),
    ExecutableProduct("b2ct", :b2ct)
]

# Dependencies that must be installed before this package can be built
# CompilerSupportLibraries_jll suggested by BinaryBuilder for OpenMP support
dependencies = [
    Dependency(PackageSpec(name="MPFR_jll", uuid="3a97d323-0669-5f0c-9066-3539efd106a3"))
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
#    Dependency(PackageSpec(name="GSL_jll", uuid="1b77fbbe-d8ee-58f0-85f9-836ddc23a7a4"))
#    Dependency(PackageSpec(name="libsvm_jll", uuid="08558c22-525a-5d2a-acf6-0ac6658ffce4"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version = v"11")

