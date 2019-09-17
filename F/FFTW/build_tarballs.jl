using BinaryBuilder

# Collection of sources required to build ZMQ
sources = [
    "http://fftw.org/~stevenj/fftw-3.3.9.tar.gz" => # prerelease tarball
    "33554751aae030b8adac2ae29384f5f4a103e02d71955aa45d613b3695eff042",
]

name = "FFTW"
version = v"3.3.9"

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fftw-*

# Base configure flags
FLAGS=(
    --prefix="$prefix"
    --host="${target}"
    --enable-shared
    --disable-static
    --disable-fortran
    --disable-mpi
    --disable-doc
    --enable-threads
    --with-combined-threads
)

# On intel processors, enable SSE2 and AVX2
if [[ "${target}" == x86_64-*  ]] || [[ "${target}" == i686-* ]]; then
    FLAGS+=( --enable-sse2 --enable-avx2 )
fi

# On x86_64, enable AVX512, once this is no longer marked "experimental" in the FFTW release notes.
# if [[ "${target}" == x86_64-* ]]; then
#    FLAGS+=( --enable-avx512 );
# fi

# Enable NEON on Aarch64
if [[ "${target}" == aarch64-* ]]; then FLAGS+=( --enable-neon ); fi

# On windows, we use our own malloc
if [[ "${target}" == *-w64-* ]]; then FLAGS+=( --with-our-malloc ); fi
if [[ "${target}" == i686-w64-* ]]; then FLAGS+=( --with-incoming-stack-boundary=2 ); fi

# On win64, we need this to avoid "Assembler Error: invalid register for .seh_savexmm",
# see https://sourceforge.net/p/mingw-w64/mailman/message/36287627/ for more info
if [[ "${target}" == x86_64-w64-* ]]; then export CFLAGS="${CFLAGS} -fno-asynchronous-unwind-tables"; fi

# On ppc64le, enable VSX
if [[ "${target}" == powerpc64le-*  ]]; then FLAGS+=( --enable-vsx ); fi

# We need to do this a couple times, so functionalize it
build_fftw()
{
    mkdir "${WORKSPACE}/srcdir/build_${1}"
    cd "${WORKSPACE}/srcdir/build_${1}"

    ${WORKSPACE}/srcdir/fftw-*/configure "${FLAGS[@]}" $2
    perl -pi -e "s/tools m4/m4/" Makefile # work around FFTW/fftw3#146
    make -j${nproc}
    make install
}

# Build the double-precision version, then the single-precision version
build_fftw double

build_fftw single --enable-single
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms() # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libfftw3", :libfftw3),
    LibraryProduct("libfftw3f", :libfftw3f),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"8")
