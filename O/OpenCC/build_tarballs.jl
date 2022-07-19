using BinaryBuilder

name = "OpenCC"
version = v"1.1.3"
sources = [
    ArchiveSource("https://github.com/BYVoid/OpenCC/archive/refs/tags/ver.$(version).tar.gz", "99a9af883b304f11f3b0f6df30d9fb4161f15b848803f9ff9c65a96d59ce877f")
]

script = raw"""
cd ${WORKSPACE}/srcdir/OpenCC*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_DOCUMENTATION:BOOL=OFF \
    ..
make -j${nproc}
make install
"""

platforms = [
  Platform("x86_64", "linux", cxxstring_abi="cxx11"),
]

products = [
  LibraryProduct("libopencc", :libopencc),
]

dependcies = Dependency[]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependcies)
