using BinaryBuilder

# Collection of sources required to build ZMQ
sources = [
    "http://fftw.org/~stevenj/fftw-3.3.9-alpha1.tar.gz" =>
    "3db033dbc8a703ed644e6973d82bf0497a15a77dc071a4391cfb844b119e7b4c",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fftw-3.3.9-alpha1
config="--prefix=$prefix --host=${target} --enable-shared --disable-static --disable-fortran --disable-mpi --disable-doc --enable-threads --with-combined-threads"
if [[ $target == x86_64-*  ]] || [[ $target == i686-* ]]; then config="$config --enable-sse2 --enable-avx2"; fi
# todo: --enable-avx512 on x86_64?
# Neon is no longer available on BinaryBuilder?
# if [[ $target == aarch64-* ]]; then
#    config="$config --enable-neon"
#    CC="${CC} -mfpu=neon"
# fi
if [[ $target == *-w64-* ]]; then config="$config --with-our-malloc"; fi
if [[ $target == i686-w64-* ]]; then config="$config --with-incoming-stack-boundary=2"; fi
# work around GNU binutils problem on MacOS (see PR #1)
if [[ ${target} == *darwin* ]]; then
    export RANLIB=llvm-ranlib
fi
mkdir double && cd double
../configure $config
perl -pi -e "s/tools m4/m4/" Makefile # work around FFTW/fftw3#146
make -j${nprocs}
make install
cd ..
if [[ $target == powerpc64le-*  ]]; then config="$config --enable-altivec"; fi
if [[ $target == arm-*  ]]; then config="$config --enable-neon"; fi
mkdir single && cd single
../configure $config --enable-single
perl -pi -e "s/tools m4/m4/" Makefile # work around FFTW/fftw3#146
make -j${nprocs}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "libfftw3", :libfftw3),
    LibraryProduct(prefix, "libfftw3f", :libfftw3f),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, "FFTW", v"3.3.9-alpha1", sources, script, platforms, products, dependencies)
