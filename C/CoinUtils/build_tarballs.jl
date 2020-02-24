# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CoinUtils"
version = v"2.11.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or/CoinUtils.git", "d4f2b7f1897b67da6929ab42aa6b1962a388c5b9"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils/

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib*/*.la

if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64-* ]]; then
    OPENBLAS=openblas64_
else
    OPENBLAS=openblas
fi

./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-blas-lib="-l${OPENBLAS}"
make -j${nproc}
make install

if [[ "${target}" == *-mingw* ]]; then
    # Manually build the shared library
    cd "${prefix}/lib"
    ar x libCoinUtils.a
    c++ -shared -o "${libdir}/libCoinUtils.${dlext}" *.o -l${OPENBLAS}
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libCoinUtils", :libCoinUtils)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
