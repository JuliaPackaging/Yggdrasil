using BinaryBuilder

name = "ZeroMQ"
version = v"4.3.1"

# Collection of sources required to build ZMQ
sources = [
    "https://github.com/zeromq/libzmq.git" =>
    "2cb1240db64ce1ea299e00474c646a2453a8435b",
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
