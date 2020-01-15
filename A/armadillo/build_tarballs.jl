# Build script for Armadillo: C++ library for linear algebra.  It contains a
# library libarmadillo.so that is a wrapper for OpenBLAS, and header files.

using BinaryBuilder

name = "armadillo"
version = v"9.800.3"
sources = [
    ("http://sourceforge.net/projects/arma/files/armadillo-9.800.3.tar.xz" =>
        "a481e1dc880b7cb352f8a28b67fe005dc1117d4341277f12999a2355d40d7599")]
script = raw"""
    cd ${WORKSPACE}/srcdir/armadillo-*/

    # Slightly different handling is needed on different platforms.
    if [[ $target == i686*mingw* ]]
    then
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/destdir/ \
            .
    elif [[ $target == x86_64*mingw* ]]
    then
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -Dopenblas_LIBRARY=$prefix/lib/libopenblas64_.a \
            -DBUILD_SHARED_LIBS=ON \
            -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/destdir/ \
            .
    else
        cmake \
            -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
            -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/destdir/ \
            .
    fi

    make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line.
platforms = supported_platforms()

# The products that we will ensure are always built.
products = [
    LibraryProduct("libarmadillo", :libarmadillo)
]

# Dependencies that must be installed before this package can be built.
dependencies = [
    "OpenBLAS_jll"
]

build_tarballs(ARGS, name, version, sources, script, platforms, products,
        dependencies)
