using BinaryBuilder, Pkg

name = "libcellml"
version = v"0.4.0"

sources = [
    GitSource(
        "https://github.com/cellml/libcellml",
        "aff96b20e268a89648dc81aa56a81dc94fab72f2"),
    DirectorySource("./bundled"),
]

# https://libcellml.org/documentation/guides/latest/installation/build_from_source
script = raw"""
cd libcellml
atomic_patch -p1 ../patches/libxml2_target_cmake.diff
mkdir build && cd build
cmake -DINSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_TYPE=Release \
    -DTWAE=OFF \
    -DCOVERAGE=OFF \
    -DLLVM_COVERAGE=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.14 \
    -DUNIT_TESTS=OFF \
    ..
make -j${nproc}
make install
"""

# It doesn't look like this works with 32-bit systems
platforms = expand_cxxstring_abis(supported_platforms(; exclude=p->nbits(p)==32))

products = [
    LibraryProduct("libcellml", :libcellml)
]

dependencies = [
    Dependency("XML2_jll"),
    Dependency("Zlib_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
