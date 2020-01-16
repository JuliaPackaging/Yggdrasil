using BinaryBuilder

name = "ZeroMQ"
version = v"4.3.2"

# Collection of sources required to build ZMQ
sources = [
    "https://github.com/zeromq/libzmq.git" =>
    "a84ffa12b2eb3569ced199660bac5ad128bff1f0",
]

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libzmq

sh autogen.sh
./configure --prefix=$prefix --host=${target} \
    --without-docs --disable-libunwind --disable-perf --disable-Werror \
    --disable-eventfd --without-gcov --disable-curve-keygen \
    CXXFLAGS="-g -O2 -fms-extensions"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libzmq", :libzmq),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
