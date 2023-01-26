#!/usr/bin/env julia
using BinaryBuilder, Pkg

name = "SBML"
version = v"5.19.7"
sources = [
    ArchiveSource(
        "https://github.com/sbmlteam/libsbml/archive/v$(version).tar.gz",
        "61cbdf1a86aefbc002ac5a0cf9c0f3f91eca2ae8aa5c3e7ef78be0f5a84426c5"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libsbml-*

mkdir build
cd build
cmake \
  -DCMAKE_INSTALL_PREFIX=${prefix} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
  -DCMAKE_LIBRARY_PATH=${libdir} \
  -DCMAKE_INCLUDE_PATH="${includedir}/libxml2;${includedir}" \
  -DENABLE_ARRAYS=ON \
  -DENABLE_COMP=ON \
  -DENABLE_DISTRIB=ON \
  -DENABLE_DYN=ON \
  -DENABLE_FBC=ON \
  -DENABLE_GROUPS=ON \
  -DENABLE_L3V2EXTENDEDMATH=ON \
  -DENABLE_LAYOUT=ON \
  -DENABLE_MULTI=ON \
  -DENABLE_QUAL=ON \
  -DENABLE_RENDER=ON \
  -DENABLE_REQUIREDELEMENTS=ON \
  -DENABLE_SPATIAL=ON \
  ..
make -j${nproc}
make install

# Remove large static library.
rm ${prefix}/lib/libsbml-static.a
"""

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    LibraryProduct("libsbml", :libsbml),
]

dependencies = [
    Dependency("XML2_jll"),
    Dependency("Zlib_jll"),
]

# GCC 6 is necessary to work around https://gcc.gnu.org/bugzilla/show_bug.cgi?id=67557
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6", julia_compat="1.6")
