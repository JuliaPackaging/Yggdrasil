#!/usr/bin/env julia
using BinaryBuilder, Pkg

name = "SBML"
version = v"5.19.0"
sources = [
    ArchiveSource(
        "https://github.com/sbmlteam/libsbml/archive/v5.19.0.tar.gz",
        "127a44cc8352f998943bb0b91aaf4961604662541b701c993e0efd9bece5dfa8"),
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
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"6")
