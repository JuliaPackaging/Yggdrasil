using BinaryBuilder

name = "FFTW"
# We bumped the version number because we rebuilt for new architectures
fftw_version = v"3.3.11"
version = v"3.3.12"

# Collection of sources required to build FFTW
sources = [
   ArchiveSource("http://fftw.org/fftw-$(fftw_version).tar.gz",	
                  "5630c24cdeb33b131612f7eb4b1a9934234754f9f388ff8617458d0be6f239a1"),
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

# Julia-Aarch64 platforms (MacOS, Linux, FreeBSD) nowadays give access to
# CNTVCT_EL0 cycle counter in userspace.  (We need to enable this explicitly
# on Linux and BSD, as otherwise FFTW will not use a cycle counter and disable
# timer-based planning.)
if [[ "${target}" == aarch64-* ]]; then FLAGS+=( --enable-armv8-cntvct-el0 ); fi

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
