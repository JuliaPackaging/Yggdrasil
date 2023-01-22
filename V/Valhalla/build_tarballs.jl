# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Valhalla"
version = v"3.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/valhalla/valhalla.git", "ea7d44af37c47fcf0cb186e7ba0f9f77e96f202a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/valhalla/

cmake -B build -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=On \
    -DENABLE_DATA_TOOLS=Off \
    -DENABLE_PYTHON_BINDINGS=Off \
    -DENABLE_BENCHMARKS=Off \
    -DENABLE_TESTS=Off \
    -DZLIB_LIBRARY=${libdir}/libz.${dlext} \
    -DZLIB_INCLUDE_DIR=${includedir} \
    -DProtobuf_INCLUDE_DIR=${includedir} \
    -DPROTOBUF_LIBRARY=${libdir}
make -C build -j$(nproc)
make -C build install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = Product[
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="protoc_jll", uuid="c7845625-083e-5bbe-8504-b32d602b7110"))
    Dependency(PackageSpec(name="LibCURL_jll", uuid="deac9b47-8bc7-5906-a0fe-35ac56dc84c0"))
    Dependency(PackageSpec(name="jq_jll", uuid="f8f80db2-c0ba-59e9-a5c3-38d72e3c5ac2"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
    Dependency(PackageSpec(name="primecount_jll", uuid="ba3b429d-c409-5a27-9e45-21aab9233266"))
    Dependency("boost_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
