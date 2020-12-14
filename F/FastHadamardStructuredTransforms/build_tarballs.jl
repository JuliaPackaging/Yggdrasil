# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "FastHadamardStructuredTransforms"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://gitlab.inria.fr/SketchedLearning/fasttransformsc.git", "5e7c023fbb89dc3c4d1bcaa41a97fc4a7bd37078"),
    GitSource("https://github.com/FALCONN-LIB/FFHT.git", "fba727a3ff72c862260460631ae1cc8e3e44e861")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/FFHT/
CFLAGS="-O3 -std=c99 -pedantic -Wall -Wshadow -Wpointer-arith -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes"
if [[ ${target} == x86_64-* ]] || [[ ${target} == i686-* ]]; then
    CFLAGS="$CFLAGS -msse -msse2 -mno-avx"
fi

$CC fht.c -o fht.o -c $CFLAGS -fPIC
$CC fast_copy.c -o fast_copy.o -c $CFLAGS -fPIC
cd $WORKSPACE/srcdir/fasttransformsc
$CC fast_transforms.c -o fast_transforms.o -I$WORKSPACE/srcdir -c $CFLAGS -fPIC -lm
mkdir -p "${libdir}"
$CC -shared fast_transforms.o ../FFHT/fht.o ../FFHT/fast_copy.o -o "${libdir}/libfasttransforms.${dlext}" $CFLAGS -lm
install_license $WORKSPACE/srcdir/fasttransformsc/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd"),
    Platform("x86_64", "windows"),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libfasttransforms", :libfasttransforms)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
