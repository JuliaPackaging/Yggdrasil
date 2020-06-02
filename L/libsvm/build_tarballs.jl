# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libsvm"
version = v"3.24.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/cjlin1/libsvm/archive/v324.tar.gz", "3ba1ac74ee08c4dd57d3a9e4a861ffb57dab88c6a33fd53eac472fc84fbb2a8f"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
for f in ${WORKSPACE}/srcdir/patches/*.patch; do
    atomic_patch -p1 ${f}
done
cd libsvm-324/
mkdir -p ${prefix}/bin
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc
    CXX=g++
fi
export OS=`uname`
make 
make lib
if [[ "${target}" == *mingw32 ]]; then
	cp libsvm.${dlext} ${prefix}/bin
else
	cp libsvm.${dlext} ${prefix}/lib
fi
cp svm-train${exeext} ${prefix}/bin
cp svm-predict${exeext} ${prefix}/bin
cp svm-scale${exeext} ${prefix}/bin
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsvm", :libsvm),
    ExecutableProduct("svm-scale", :svm_scale),
    ExecutableProduct("svm-train", :svm_train),
    ExecutableProduct("svm-predict", :svm_predict)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
