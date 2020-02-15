# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "COINBLAS"
version = v"1.4.8"

# Collection of sources required to complete build
sources = [
    FileSource("https://github.com/coin-or-tools/ThirdParty-Blas/archive/releases/1.4.8.tar.gz", "781283ede62fc58e4eabcd0da00e8853e7001246a0fc4d7dd63207681ef1afff"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ThirdParty-Blas-*/
update_configure_scripts
./get.Blas 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --with-pic \
    --disable-pkg-config \
    --enable-shared \
    --disable-static \
    --enable-dependency-linking \
    lt_cv_deplibs_check_method=pass_all
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:i686, libc=:glibc),
    Linux(:x86_64, libc=:glibc),
    Linux(:aarch64, libc=:glibc),
    Linux(:armv7l, libc=:glibc, call_abi=:eabihf),
    Linux(:i686, libc=:musl),
    Linux(:x86_64, libc=:musl),
    Linux(:aarch64, libc=:musl),
    Linux(:armv7l, libc=:musl, call_abi=:eabihf),
    MacOS(:x86_64),
    Windows(:i686),
    Windows(:x86_64)
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libcoinblas", :libcoinblas)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
