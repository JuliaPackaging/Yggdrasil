using BinaryBuilder

name = "FFTW"
# We bumped the version number because we rebuilt for new architectures
fftw_version = v"3.3.10"
version = v"3.3.11"

# Collection of sources required to build FFTW
sources = [
   ArchiveSource("http://fftw.org/fftw-$(fftw_version).tar.gz",	
                  "56c932549852cddcfafdab3820b0200c7742675be92179e59e6215b340e26467"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fftw*

# Base configure flags
FLAGS=(
    --prefix="$prefix"
    --build=${MACHTYPE}
    --host="${target}"
    --enable-shared
    --disable-static
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

# On ppc64le, enable VSX
if [[ "${target}" == powerpc64le-*  ]]; then FLAGS+=( --enable-vsx ); fi

# We need to do this a couple times, so functionalize it
build_fftw()
{
    mkdir "${WORKSPACE}/srcdir/build_${1}"
    cd "${WORKSPACE}/srcdir/build_${1}"

    ${WORKSPACE}/srcdir/fftw*/configure "${FLAGS[@]}" $2
    perl -pi -e "s/tools m4/m4/" Makefile # work around FFTW/fftw3#146
    make -j${nproc}
    make install
}

# Build the double-precision version, then the single-precision version
build_fftw double

build_fftw single --enable-single

# Install both COPYING and COPYRIGHT in the license directory
cd ${WORKSPACE}/srcdir/fftw*
install_license COPYING COPYRIGHT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true) # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libfftw3", :libfftw3),
    LibraryProduct("libfftw3f", :libfftw3f),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
