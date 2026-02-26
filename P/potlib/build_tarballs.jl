using BinaryBuilder, Pkg

name = "potlib"
version = v"0.1.0"

sources = [
    GitSource("https://github.com/HaoZeke/potlib.git", 
              "9fd43a3c1dd826bfc15ad7df105d5f81377ce678"),
]

script = raw"""
cd $WORKSPACE/srcdir/potlib

mkdir build
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DPOTLIB_RPC_CLIENT_ONLY=ON \
    -DCAPNP_EXECUTABLE=${host_bindir}/capnp \
    -DCAPNPC_CXX_EXECUTABLE=${host_bindir}/capnpc-c++

cmake --build build --parallel ${nproc}
cmake --install build
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libptlrpc", :libptlrpc),
    LibraryProduct("libpot_client_bridge", :libpot_client_bridge),
]

dependencies = [
    HostBuildDependency("capnproto_jll"),
    Dependency("capnproto_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies,
               julia_compat="1.6", preferred_gcc_version=v"9")
