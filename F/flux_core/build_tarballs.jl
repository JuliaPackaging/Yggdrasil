using BinaryBuilder

name = "flux_core"
version = v"0.23.1"

# Collection of sources required to build ZMQ
sources = [
    GitSource("https://github.com/flux-framework/flux-core.git", "5ca51ac62b36b83598c5c2c4c06bff4948e389fa"),
    DirectorySource("./bundled/"),
]

# Bash recipe for building across all platforms
script = raw"""
apk add python3

cd $WORKSPACE/srcdir/flux-core
atomic_patch -p1 ../patches/zeromq_cc.patch
atomic_patch -p1 ../patches/signal-h.patch

sh autogen.sh

# Hint to find libstc++, required to link against C++ libs when using C compiler
if [[ "${target}" == *-linux-* ]]; then
    if [[ "${nbits}" == 32 ]]; then
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib"
    else
        export CFLAGS="-Wl,-rpath-link,/opt/${target}/${target}/lib64"
    fi
fi

export LUA=${host_bindir}/lua
export LUA_INCLUDE=-I${prefix}/include
export LUA_LIB=-llua

export PYTHON=python3

./configure --prefix=$prefix --host=${target} --without-python

make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# - MacO/BSDS: https://github.com/flux-framework/flux-core/issues/2892
# - Windows: Non-goal
# - MUSL: https://github.com/flux-framework/flux-core/issues/2891
platforms = [
    # Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    # Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libflux-core", :libflux_core),
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
