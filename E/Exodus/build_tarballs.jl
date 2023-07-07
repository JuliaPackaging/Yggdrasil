# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Exodus"
version = v"8.19.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/gsjaardema/seacas.git", "cfc1edd1e1602fd1edc8da90053b66e92499c8e9"),
    DirectorySource("bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/seacas

for p in ../patches/*.patch; do
    atomic_patch -p1 "${p}"
done

mkdir build
cd build

cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    \
    -D CMAKE_CXX_FLAGS="-Wall -Wunused -pedantic" \
    -D CMAKE_C_FLAGS="-Wall -Wunused -pedantic -std=c11" \
    -D CMAKE_Fortran_FLAGS="" \
    -D Seacas_ENABLE_STRONG_C_COMPILE_WARNINGS="" \
    -D Seacas_ENABLE_STRONG_CXX_COMPILE_WARNINGS="" \
    -D CMAKE_INSTALL_RPATH:PATH="${libdir}" \
    -D BUILD_SHARED_LIBS:BOOL=YES \
    -D Seacas_ENABLE_SEACASExodus=YES \
    -D Seacas_ENABLE_SEACASExodus_for=NO \
    -D Seacas_ENABLE_SEACASExoIIv2for32=NO \
    -D Seacas_ENABLE_TESTS=NO \
    -D SEACASExodus_ENABLE_STATIC:BOOL=NO \
    -D Seacas_SKIP_FORTRANCINTERFACE_VERIFY_TEST:BOOL=YES \
    -D Seacas_HIDE_DEPRECATED_CODE:BOOL=NO \
    -D Seacas_ENABLE_Fortran=NO \
    \
    -DSeacas_ENABLE_SEACASNemslice:BOOL=ON \
    -DSeacas_ENABLE_SEACASNemspread:BOOL=ON \
    \
    -DSeacas_ENABLE_SEACASEpu:BOOL=ON \
    \
    -DSeacas_ENABLE_SEACASExodiff:BOOL=ON \
    \
    -D TPL_ENABLE_Netcdf:BOOL=YES \
    -D TPL_ENABLE_MPI:BOOL=NO \
    -D TPL_ENABLE_Pthread:BOOL=NO \
    -D SEACASExodus_ENABLE_THREADSAFE:BOOL=NO \
    \
    -D NetCDF_ROOT:PATH=${prefix} \
    -D HDF5_ROOT:PATH=${prefix} \
    -D HDF5_NO_SYSTEM_PATHS=YES \
    -D PNetCDF_ROOT:PATH=${prefix} \
    \
    ..

make -j${nproc}
make install

# below is an absolute hack to fix a tree hash mismatch on macos
# this is due to a case insensitivity issue. 
#
# The issue is caused by a duplicate folder in destdir/lib/cmake
# called "Seacas" which is a duplibcate of "SEACAS".
#
# The build process has far too many CMake files to track this down.
#
rm -r "${prefix}/lib/cmake/Seacas"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64","macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libexodus", :libexodus)
    ExecutableProduct("nem_slice", :nem_slice_exe)
    ExecutableProduct("nem_spread", :nem_spread_exe)
    ExecutableProduct("exodiff", :exodiff_exe)
    ExecutableProduct("epu", :epu_exe)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Fmt_jll", uuid="5dc1e892-f187-50dd-85f3-7dff85c47fc5"))
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"); compat="~1.14")
    Dependency(PackageSpec(name="NetCDF_jll", uuid="7243133f-43d8-5620-bbf4-c2c921802cf3"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
