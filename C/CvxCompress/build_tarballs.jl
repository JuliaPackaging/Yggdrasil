# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CvxCompress"
version = v"1.0.0"

# Collection of sources required to build CvxCompress
sources = [
    GitSource(
        "https://github.com/ChevronETC/CvxCompress.git",
        "55e072862196e917e3ecece81f014e93d60cdf81"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across platforms
script = raw"""
cd ${WORKSPACE}/srcdir/CvxCompress
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross-compile-cvxcompress-gencode.patch
${CXX_FOR_BUILD} -O2 -o CvxCompress_GenCode Wavelet_Transform_Slow.cpp CvxCompress_GenCode.cpp
./CvxCompress_GenCode
FLAGS=()
if [[ "${target}" == *-apple-* ]]; then
    FLAGS=(LDFLAGS="-fopenmp -lm")
fi
make -j${nproc} "${FLAGS[@]}"
mkdir -p ${libdir}
cp libcvxcompress.so ${libdir}/libcvxcompress.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# TODO update make to adjust the intrinsic code generation to support more platforms
platforms = [p for p in supported_platforms() if arch(p) === :x86_64 && !Sys.iswindows(p)]

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
