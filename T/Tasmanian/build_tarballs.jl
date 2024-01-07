# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Tasmanian"
version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ORNL/TASMANIAN.git", "10a762e036c58b2aee4dbf21137aff8401acf0a3")
]

BLAS="blastrampoline"
LAPACK="blastrampoline"
# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TASMANIAN
mkdir build && cd build
export CXXFLAGS=-Dsgemm_=sgemm_64
if [[ "${target}" == *-freebsd* ]]; then
    export LDFLAGS="-lpthread"
fi
cmake -DCMAKE_INSTALL_PREFIX=$prefix \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBLAS_LIBRARIES="-l${BLAS}" \
    -DLAPACK_LIBRARIES="-l${LAPACK}" \
    -DTasmanian_ENABLE_RECOMMENDED=ON \
    -DTasmanian_ENABLE_PYTHON=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libtasmaniansparsegrid", :libtasmaniansparsegrid),
    LibraryProduct("libtasmaniandream", :libtasmaniandream)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("libblastrampoline_jll"),
    Dependency("CompilerSupportLibraries_jll"),
]

# License file

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
