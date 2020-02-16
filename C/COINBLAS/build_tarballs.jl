# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "COINBLAS"
version = v"1.4.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/coin-or-tools/ThirdParty-Blas.git", "d229cc63c8780dfd69285a2e2fe1ef688b982d8d"),
    FileSource("https://github.com/coin-or-tools/BuildTools/archive/releases/0.8.10.tar.gz", "6b149acb304bf6fa0d8c468a03b1f67baaf981916b016bc32db018fa512e4f88"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ThirdParty-Blas/
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
platforms = expand_gfortran_versions(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libcoinblas", :libcoinblas)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
