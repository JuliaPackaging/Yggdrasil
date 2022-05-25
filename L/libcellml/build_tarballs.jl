#!/usr/bin/env julia
using BinaryBuilder, Pkg

name = "libcellml"
version = v"0.2.0"
sources = [
    GitSource(
        "https://github.com/cellml/libcellml",
        "9948e5fb6159bbe50bbe0f4bec883ed7190a51f7"),
]

# https://libcellml.org/documentation/guides/latest/installation/build_from_source
script = raw"""
mv libcellml source
mkdir build
mkdir install
cd build
cmake -DINSTALL_PREFIX=../install -S "../source" -B=.

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

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
