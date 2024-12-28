# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "nats_c"
version = v"3.6.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/nats-io/nats.c.git", "ab983febcff5d6077d8db1a919a74f0ac1a53ef7"),
    DirectorySource("./bundled")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir

# Fix "cannot finding openssl" under Windows
if [[ ${target} == x86_64-w64-mingw32 ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64/
fi

cd nats.c/
atomic_patch -p1 ../patches/freebsd_include.diff
sed -i 's/Ws2_32/ws2_32/g' CMakeLists.txt
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DNATS_BUILD_EXAMPLES=OFF -DNATS_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF ..
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libnats", :libnats)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="protobuf_c_jll", uuid="d730a6b3-54e8-5a61-8821-996059275344"))
    Dependency(PackageSpec(name="OpenSSL_jll", uuid="458c3c95-2e84-50aa-8efc-19380b2a3a95"); compat="3.0.8")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"9.1.0")
