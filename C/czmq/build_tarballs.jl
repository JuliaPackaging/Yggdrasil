using BinaryBuilder

name = "czmq"
version = v"4.2.1"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/zeromq/czmq.git", "4a50c2153586cf510d6cc3fcfbb9f5ea2e02c419"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/czmq
sh autogen.sh

# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
fi

./configure --prefix=$prefix \
    --host=${target} \
    --enable-drafts \
    --disable-static \
    CXXFLAGS="-O2 -fms-extensions"
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = expand_cxxstring_abis(supported_platforms())

# The products that we will ensure are always built
products = [
    LibraryProduct("libczmq", :libczmq),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
    Dependency("ZeroMQ_jll", v"4.3")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
