using BinaryBuilder

name = "nlminb"
version = v"0.1.0"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/geo-julia/nlminb.f.git",
              "6b2d460b866911e8bfca32b1217c08fb78c3111f"), # v0.1.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlminb.f
mkdir build 
cd build

if [[ "${nbits}" == 64 ]] && [[ "${target}" != aarch64* ]]; then
    OPENBLAS="${libdir}/libopenblas64_.${dlext}"
else
    OPENBLAS="${libdir}/libopenblas.${dlext}"
fi

# -DBLAS_LIBRARIES=${libdir}/libopenblas.${dlext}
CMAKE_FLAGS+=(-DCMAKE_INSTALL_PREFIX=${prefix}
              -DBLAS_LIBRARIES=${OPENBLAS}
              -DCMAKE_BUILD_TYPE=Release
              )
        
cmake ${CMAKE_FLAGS[@]} ..
make -j${nproc}
make install
"""
# -DBLAS_LIBRARIES="-l${LIBOPENBLAS}"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = expand_gfortran_versions(supported_platforms()) # build on all supported platforms
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
]
platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlminb", :libnlminb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("OpenBLAS_jll"),
    Dependency("CompilerSupportLibraries_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
