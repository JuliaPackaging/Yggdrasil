# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CoinUtils"
version = v"2.11.4"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/coin-or/CoinUtils/archive/releases/$(version).tar.gz",
                  "d4effff4452e73356eed9f889efd9c44fe9cd68bd37b608a5ebb2c58bd45ef81"),
    ArchiveSource("https://github.com/coin-or-tools/BuildTools/archive/releases/0.8.10.tar.gz",
                  "6b149acb304bf6fa0d8c468a03b1f67baaf981916b016bc32db018fa512e4f88"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/CoinUtils-*/
update_configure_scripts

if [[ "${target}" == powerpc64le-* ]] || [[ "${target}" == *-freebsd* ]] ; then
    # It looks like the directory with the definition of the M4 macros *must* be
    # called `BuildTools` and stay under the current directory.
    mv ../BuildTools-releases-0.8.10/ BuildTools
    # Patch `configure.ac` to look for this directory
    atomic_patch -p1 ../patches/configure_add_config_macro_dir.patch
    # Run autoreconf to be able to build the shared libraries for PowerPC and FreeBSD
    autoreconf -vi
fi

# Remove wrong libtool files
rm -f /opt/${target}/${target}/lib64/*.la
rm -f /opt/${target}/${target}/lib/*.la

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
platforms = filter!(p -> !(isa(p, FreeBSD) || p == Linux(:powerpc64le, libc=:glibc)), supported_platforms())
platforms = expand_gfortran_versions(expand_cxxstring_abis(platforms))

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
