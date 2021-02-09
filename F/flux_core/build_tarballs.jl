using BinaryBuilder

name = "flux_core"
version = v"0.23.1"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/flux-framework/flux-core.git", "5ca51ac62b36b83598c5c2c4c06bff4948e389fa"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/flux-core
sh autogen.sh

export LUA=${host_bindir}/lua
export LUA_INCLUDE=${prefix}/include
export LUA_LIB=-llua

./configure --prefix=$prefix --host=${target} --without-python

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libflux_core", :libczmq),
    ExecutableProduct("flux", :flux),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("libsodium_jll"),
    Dependency("ZeroMQ_jll"),
    Dependency("czmq_jll"),
    Dependency("Jansson_jll"),
    Dependency("Libuuid_jll"),
    Dependency("Lz4_jll"),
    Dependency("Hwloc_jll"),
    Dependency("SQLite_jll"),
    Dependency("Lua_jll"),
    HostBuildDependency("Lua_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)