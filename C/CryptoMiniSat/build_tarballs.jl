# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CryptoMiniSat"
version = v"5.8.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/msoos/cryptominisat.git", "e7079937ed2bfe9160a104378e5a344028e4ab78"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/cryptominisat
atomic_patch -p1 ../Yalsatpatch.patch
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_PYTHON_INTERFACE=OFF \
    -DIPASIR=ON \
    -DNOM4RI=ON \
    ..
make -j${nproc}
make install
install_license ${WORKSPACE}/srcdir/cryptominisat/LICENSE.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = Product[
    ExecutableProduct(["cryptominisat5", "cryptominisat5win"], :cryptominisat5),
    ExecutableProduct("cryptominisat5_simple", :cryptominisat5_simple),
    LibraryProduct(["libcryptominisat5", "libcryptominisat5win"], :libcryptominisat5),
    LibraryProduct("libipasircryptominisat5", :libipasircryptominisat5)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("boost_jll"),
    Dependency("Zlib_jll"),
    Dependency("SQLite_jll"),
    Dependency("MPICH_jll"),
    Dependency("MicrosoftMPI_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
