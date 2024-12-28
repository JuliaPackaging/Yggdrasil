using BinaryBuilder

name = "spdlog"
version = v"1.15.0"

sources = [
    GitSource("https://github.com/gabime/spdlog.git",
              "27cb4c76708608465c413f6d0e6b8d99a4d84302"),
    DirectorySource("./bundled"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/spdlog*

# Patch to fix compilation with fmt 11.1.1
atomic_patch -p1 ../patches/fmt_11.1.1.patch

mkdir build
cd build
cmake -S .. -B . \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DSPDLOG_FMT_EXTERNAL=ON \
    -DSPDLOG_BUILD_SHARED=ON \
    -DSPDLOG_BUILD_PIC=ON \
    -DSPDLOG_BUILD_EXAMPLE=OFF

make -j${nproc} install
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libspdlog", :libspdlog)
]

dependencies = [
    Dependency("Fmt_jll"; compat="11.1.1")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
