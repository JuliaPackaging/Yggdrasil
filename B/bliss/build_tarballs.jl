# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "bliss"
version = v"0.77.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://users.aalto.fi/~tjunttil/bliss/downloads/bliss-0.77.zip", "acc8b98034f30fad24c897f365abd866c13d9f1bb207e398d0caf136875972a4"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bliss-*

atomic_patch -p1 ../patches/gmp_def.patch
atomic_patch -p1 ../patches/cmake_gmp.patch

cd build

cmake -DCMAKE_INSTALL_PREFIX=$prefix\
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN}\
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_GMP=ON ..
make -j${nproc}
install -Dm 755 "bliss${exeext}" "${bindir}/bliss${exeext}"
install -Dm 755 "libbliss.${dlext}" "$libdir/libbliss.${dlext}"

mkdir -p $prefix/include/bliss
install -p -m 0644 -t "${includedir}/bliss" ../src/*.hh

install_license ../COPYING.LESSER
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libbliss", :libbliss),
    ExecutableProduct("bliss", :bliss),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll", v"6.2.1"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"7")
