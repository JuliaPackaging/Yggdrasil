# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CvxCompress"
version = v"1.2.1"

# Collection of sources required to build CvxCompress
sources = [
    GitSource(
        "https://github.com/ChevronETC/CvxCompress.git",
        "3d686fef6a2a08edaaece541ba852f43cf59abf1"
    ),
    DirectorySource("./bundled"),
]

# Bash recipe for building across platforms
script = raw"""
install_license ${WORKSPACE}/srcdir/CvxCompress/LICENSE.md

cd ${WORKSPACE}/srcdir/CvxCompress
atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cross-compile-cvxcompress-gencode.patch
# Pull simde
git submodule update --init

${CXX_FOR_BUILD} -O2 -o CvxCompress_GenCode Wavelet_Transform_Slow.cpp CvxCompress_GenCode.cpp
./CvxCompress_GenCode

if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi

# Build
make -j${nproc} lib

# Install
install -Dvm 755 libcvxcompress.${dlext} "${libdir}/libcvxcompress.${dlext}"
install -Dvm 644 CvxCompress.hxx "${includedir}/CvxCompress.hxx"

"""
# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=Sys.iswindows)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcvxcompress", :libcvxcompress)
    FileProduct("include/CvxCompress.hxx", :CvxCompress_hxx)
    # FileProduct("include/CvxCompress.h", :CvxCompress_h)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"10")
