using BinaryBuilder

name = "LibSnowflakeClient"
version = v"1.0.12"

sources = [
    GitSource("https://github.com/snowflakedb/libsnowflakeclient.git",
              "aebf0412765e38d4911b8c60a0df20ee2551d8ef"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libsnowflakeclient

mkdir build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTS=OFF \
    -DMOCK=OFF \
    -DCLIENT_CODE_COVERAGE=OFF \
    ..
make -j${nproc}
make install
"""

platforms = supported_platforms()

products = [
    LibraryProduct("libsnowflakeclient", :libsnowflakeclient),
]

# TODO: libsnowflakeclient builds its own vendored Arrow, AWS C++ SDK, Azure Storage C++
# client, Boost, C mocking library, CURL, out-of-band telemetry library, OpenSSL, libuuid,
# and zlib. We can probably get it to use BinaryBuilder dependencies with shared libraries
# rather than vendored dependencies with static libraries, though it'd probably take some
# (possibly extensive) patching.
dependencies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
