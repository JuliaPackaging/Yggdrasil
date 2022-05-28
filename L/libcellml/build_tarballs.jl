using BinaryBuilder, Pkg

name = "libcellml"
version = v"0.2.0"

sources = [
    GitSource(
        "https://github.com/cellml/libcellml",
        "9948e5fb6159bbe50bbe0f4bec883ed7190a51f7"),
    DirectorySource("./bundled"),
]

# https://libcellml.org/documentation/guides/latest/installation/build_from_source
script = raw"""
cd libcellml
atomic_patch -p1 ../patches/libxml2_target_cmake.diff
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    ..
make -j${nproc}
make install
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libcellml", :libcellml)
]

dependencies = [
    Dependency("XML2_jll"),
    Dependency("Zlib_jll")
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"7")
