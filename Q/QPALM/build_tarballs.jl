# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "QPALM"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Benny44/QPALM_vLADEL.git", "370ccbeb33baaa566c3de2bde5a69944994593e2"),
    GitSource("https://github.com/Benny44/LADEL.git", "585b766da25e028f368e4d9039ef69e326baeb5b"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd QPALM_vLADEL/
ln -s ${WORKSPACE}/srcdir/LADEL/* ${WORKSPACE}/srcdir/QPALM_vLADEL/LADEL/
[[ $target == *-freebsd* ]] && patch -p1 < $WORKSPACE/srcdir/patches/freebsd.patch
mkdir -p build
cd build
mkdir lib debug
cd debug  # just following the instructions here

[[ $target == *-mingw* ]] && BLAS=libopenblas.${dlext}.a || BLAS=libopenblas.${dlext}
[[ $target == *-linux-* ]] && std="gnu99" || std="c99"

cmake ../.. \
      -DCMAKE_BUILD_TYPE=release \
      -DCMAKE_INSTALL_PREFIX=$prefix \
      -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
      -DUSE_LADEL=ON \
      -DUSE_CHOLMOD=ON \
      -DINTERFACES=OFF \
      -DPYTHON=OFF \
      -DCOVERAGE=OFF \
      -DUNITTESTS=OFF \
      -DJULIA=OFF \
      -DLAPACKE=${prefix}/lib/${BLAS} \
      -DLAPACK=${prefix}/lib/${BLAS} \
      -DCMAKE_C_FLAGS="-I${includedir} -std=${std}"

make

# make install doesn't appear to work...
if [[ $target == *-mingw* ]]; then
  # headers don't make it to build/include
  cp ../../include/* $prefix/include
  cp bin/* $prefix/bin
else
  cp ../include/* $prefix/include
  cp ../lib/* $prefix/lib
fi
cd ../..
mv LICENSE LICENSE.QPALM
install_license LICENSE.QPALM
mv ${WORKSPACE}/srcdir/LADEL/LICENSE ./LICENSE.LADEL
install_license LICENSE.LADEL
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
products = Product[
                   LibraryProduct("libladel", :libladel),
                   LibraryProduct("libqpalm", :libqpalm),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2"))
    Dependency(PackageSpec(name="SuiteSparse_jll", uuid="bea87d4a-7f5b-5778-9afe-8cc45184846c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
