# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CvxCompress"
version = v"1.0.0"

# Collection of sources required to build CvxCompress
sources = [
    GitSource(
        "https://github.com/ChevronETC/CvxCompress.git",
        "89928d6639661a246d0a36ccbbc3469bd6de1a8d"
    )
]

# Bash recipe for building across platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CvxCompress
make -j${nproc}
mkdir -p ${libdir}
cp libcvxcompress.so ${libdir}/libcvxcompress.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
  Linux(:x86_64, libc=:glibc)
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libcvxcompress", :libcvxcompress)
]

# Dependencies that must be installed before this package can be built
dependencies = []

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
