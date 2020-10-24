using BinaryBuilder, Pkg

name = "HelFEM"
version = v"0.0.1"
sources = [
    GitSource("https://github.com/mortenpi/HelFEM.git", "d3b9ce4d34fcce3296a80aef0ed9b60ce45319c9")
]

script = raw"""
cp -v ${WORKSPACE}/srcdir/HelFEM/julia/CMake.system ${WORKSPACE}/srcdir/HelFEM/CMake.system

# Set up some platform specific CMake configuration. This is more or less borrowed from
# the Armadillo build_tarballs.jl script:
#   https://github.com/JuliaPackaging/Yggdrasil/blob/48d7a89b4aa46b1a8c91269bb138a660f4ee4ece/A/armadillo/build_tarballs.jl#L23-L52
#
# We need to manually set up OpenBLAS because FindOpenBLAS.cmake does not work with BB:
if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64* ]]; then
    OPENBLAS="${libdir}/libopenblas64_.${dlext}"
else
    OPENBLAS="${libdir}/libopenblas.${dlext}"
fi

# On i686, it seems that we need to explicitly tell GCC that we want SSE2. Refs:
#   https://github.com/JuliaLang/julia/blob/v1.4.1/src/atomics.h#L8-L10
#   https://stackoverflow.com/questions/16410149/error-sse2-instruction-set-not-enabled-when-including-emmintrin-h
if [[ "${target}" == i686* ]]; then
    export CXXFLAGS="-msse -msse2"
fi

# Compile libhelfem as a static library
cd ${WORKSPACE}/srcdir/HelFEM/
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DUSE_OPENMP=OFF \
    -DHELFEM_BINARIES=OFF -DHELFEM_FIND_DEPS=ON \
    -B build/ -S .
make -C build/ -j${nproc} helfem
make -C build/ install
# Copy the HelFEM license
install_license LICENSE

# Compile the CxxWrap wrapper as a shared library
cd ${WORKSPACE}/srcdir/HelFEM/julia
cmake \
    -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release \
    -DBLAS_LIBRARIES=${OPENBLAS} \
    -DJulia_PREFIX=$prefix -DCMAKE_FIND_ROOT_PATH=$prefix -DJlCxx_DIR=$prefix/lib/cmake/JlCxx \
    -B build/ -S .
make -C build/ -j${nproc}
make -C build/ install
"""

# These are the platforms libcxxwrap_julia_jll is built on.
#
# The libgfortran constraint is necessary because the default is libgfortran 3, but the
# Julia_jll is only available for libgfortran 4.
platforms = [
    Platform("x86_64", "linux"; libc="glibc", cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("i686", "linux"; libc="glibc", cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("armv7l", "linux"; libc="glibc", cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("aarch64", "linux"; libc="glibc", cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("x86_64", "macos", libgfortran_version=v"4"),
    Platform("x86_64", "windows"; cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("i686", "windows"; cxxstring_abi = "cxx11", libgfortran_version=v"4"),
    Platform("x86_64", "freebsd", libgfortran_version=v"4"),
]

products = [
    LibraryProduct("libhelfem-cxxwrap", :libhelfem),
]

dependencies = [
    BuildDependency(PackageSpec(name = "Julia_jll", version = "1.4.1")),
    Dependency(PackageSpec(name = "libcxxwrap_julia_jll", version = "0.8.0")),
    Dependency(PackageSpec(name = "armadillo_jll", version = "9.850.1")),
    Dependency(PackageSpec(name = "GSL_jll", version = "2.6.0")),
    Dependency(PackageSpec(name = "OpenBLAS_jll", version = "0.3.9")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
