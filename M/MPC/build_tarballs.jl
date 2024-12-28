# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "MPC"
version = v"1.3.1"

# Collection of sources required to build MPC
sources = [
    ArchiveSource("https://ftp.gnu.org/gnu/mpc/mpc-$(version).tar.gz",
                  "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/mpc-*
./configure --prefix=${prefix} \
    --build=${MACHTYPE} \
    --host=${target} \
    --enable-shared \
    --disable-static \
    --with-gmp=${prefix} \
    --with-mpfr=${prefix}
make -j${nproc}
make install
install_license COPYING*

# On Windows, make sure non-versioned filename exists...
if [[ ${target} == *mingw* ]]; then
    cp -v ${libdir}/libmpc-*.dll ${libdir}/libmpc.dll
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmpc", :libmpc)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.2.0"),
    Dependency("MPFR_jll", v"4.1.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               preferred_gcc_version=v"5", julia_compat="1.6")
