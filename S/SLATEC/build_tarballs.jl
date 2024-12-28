# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SLATEC"
version = v"4.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/sabjohnso/slatec.git",
              "417db9e31c49eba4aee5ab9bb719093f6886bcee"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/slatec
# BLAS/LAPACK is linked with libblastrampoline
sed -i -e 's/"Link to the system BLAS library?" ON )/"Link to the system BLAS library?" OFF )/g' CMakeLists.txt
# Do not build tests
sed -i -e 's/"Build the SLATEC tests?" ON )/"Build the SLATEC tests?" OFF )/g' CMakeLists.txt

cd $WORKSPACE/srcdir/slatec/src

# Prepend undscore to symbols with i686 mingw target
if [[ $target == *"i686-w64-mingw32" ]]; then 
    sed -i '/add_library( slatec_shared SHARED ${SLATEC_SOURCE_FILES} )/a\
    target_compile_options(slatec_shared PUBLIC -fleading-underscore)
    ' CMakeLists.txt
fi

# libblastrampoline-5 required for mingw32
if [[ $target == *"w64-mingw32" ]]; then
    LBT=blastrampoline-5
else
    LBT=blastrampoline
fi
# Change lapack library to libblastrampoline
sed -i -e "s/target_link_libraries( slatec_shared blas lapack )/target_link_libraries( slatec_shared ${LBT} )/g" CMakeLists.txt

if [[ "${target}" == aarch64-apple-* ]]; then
    # Fix issue due to GCC 10+.
    #     [  2%] Building Fortran object src/CMakeFiles/slatec_shared.dir/dwnlsm.f.o
    #     cd /workspace/srcdir/slatec/build/src && /opt/bin/aarch64-apple-darwin20-libgfortran5-cxx11/aarch64-apple-darwin20-gfortran --sysroot=/opt/aarch64-apple-darwin20/aarch64-apple-darwin20/sys-root -Dslatec_shared_EXPORTS  -O3 -DNDEBUG -O3 -fPIC   -c /workspace/srcdir/slatec/src/dwnlsm.f -o CMakeFiles/slatec_shared.dir/dwnlsm.f.o
    #     /workspace/srcdir/slatec/src/dwnlsm.f:440:28:
    #
    #       119 |       CALL DCOPY (N, 1.D0, 0, D, 1)
    #           |                     2
    #     ......
    #       440 |          CALL DCOPY (NSOLN, Z, 1, X, 1)
    #           |                            1
    #     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
    #     /workspace/srcdir/slatec/src/dwnlsm.f:608:25:
    #
    #       119 |       CALL DCOPY (N, 1.D0, 0, D, 1)
    #           |                     2
    #     ......
    #       608 |       CALL DCOPY (NSOLN, Z, 1, X, 1)
    #           |                         1
    #     Error: Rank mismatch between actual argument at (1) and actual argument at (2) (scalar and rank-1)
    export FFLAGS="-fallow-argument-mismatch"
fi


mkdir ../build
cd ../build/
# Build shared library
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_OPTIMIZED_BLAS=0 \
    -DBUILD_SHARED_LIBRARY=1 \
    ..
make -j${nproc}
make install

install_license ../../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line

platforms = expand_gfortran_versions(supported_platforms(; experimental=true))
# lapack build by default only for gfortran5 on aarch64
filter!(p -> !(arch(p) == "aarch64" && Sys.islinux(p) && libgfortran_version(p) != v"5"), platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libslatec", :libslatec)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libblastrampoline_jll"); compat="5.4"),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
# For the time being need LLVM 11 because of <https://github.com/JuliaPackaging/BinaryBuilderBase.jl/issues/158>.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.9", preferred_llvm_version=v"11")
