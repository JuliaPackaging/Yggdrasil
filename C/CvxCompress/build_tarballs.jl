# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "CvxCompress"
version = v"1.0.0"

# Collection of sources required to build CvxCompress
sources = [
    GitSource(
        "https://github.com/ChevronETC/CvxCompress.git",
        "55e072862196e917e3ecece81f014e93d60cdf81"
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
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libcvxcompress", :libcvxcompress)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
