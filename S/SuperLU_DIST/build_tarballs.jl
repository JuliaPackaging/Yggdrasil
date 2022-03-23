# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SuperLU"
version = v"7.2.0"

# Collection of sources required to complete build
sources = [
    # We are using the most recent master as of this build rather than v7.2.0 release.
    # The release is strangely missing .h files that are necessary for build.
    # They exist on master.
    GitSource("https://github.com/xiaoyeli/superlu_dist.git", "b430c074a19bdfd897d5e2a285a85bc819db12e5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/superlu_dist*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DTPL_ENABLE_INTERNAL_BLASLIB=OFF \
    -Denable_tests=OFF \
    -Denable_doc=OFF \
    -Denable_single=ON \
    -Denable_double=ON \
    -Denable_complex16=ON \
    -DTPL_BLAS_LIBRARIES="${libdir}/libopenblas.${dlext}" \
    -DTPL_PARMETIS_INCLUDE_DIRS="${includedir}" \
    -DTPL_PARMETIS_LIBRARIES="${libdir}/libparmetis.${dlext};${libdir}/libmetis.${dlext}" \
    -DCMAKE_C_FLAGS="-std=c99" \
    -DXSDK_INDEX_SIZE=32 \
    ..
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # Manually install the library
    cp "SRC/libsuperlu.${dlext}" "${libdir}/libsuperlu.${dlext}"
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libsuperlu", :libsuperlu)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="OpenBLAS32_jll", uuid="656ef2d0-ae68-5445-9ca0-591084a874a2")),
    Dependency(PackageSpec(name="PARMETIS_jll", uuid="b247a4be-ddc1-5759-8008-7e02fe3dbdaa")),
    Dependency("MPICH_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
