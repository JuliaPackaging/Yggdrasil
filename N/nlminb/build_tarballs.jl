using BinaryBuilder

name = "nlminb"
version = v"0.1.0"

# Collection of sources required to build NLopt
sources = [
    GitSource("https://github.com/geo-julia/nlminb.f.git",
              "1aba02cd2fe994ebb52b27caea1335a4189c1d45"), # v0.1.0
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/nlminb.f
cd lib && tar -xvzf blas-3.8.0.tgz \
    && cd BLAS-3.8.0 && make && cd ../../
mkdir build 
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release ..
make -j${nproc}
make install
"""
# -DBLAS_LIBRARIES="-l${LIBOPENBLAS}"

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms()) # build on all supported platforms

# The products that we will ensure are always built
products = [
    LibraryProduct("libnlminb", :libnlminb),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
