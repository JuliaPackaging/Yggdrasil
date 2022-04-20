using BinaryBuilder

name = "CGNS"
version = v"4.3.0"
sources = [
    ArchiveSource("https://github.com/CGNS/CGNS/archive/refs/tags/v4.3.0.tar.gz", "7709eb7d99731dea0dd1eff183f109eaef8d9556624e3fbc34dc5177afc0a032"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/CGNS*
mkdir build && cd build
H5LIB=""
if [[ "${target}" == *-mingw* ]]; then
    H5LIB="-DHDF5_hdf5_LIBRARY_RELEASE=$(ls ${WORKSPACE}/destdir/bin/libhdf5-*.${dlext})"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
      ${H5LIB} ..
make -j${nproc}
make install
"""

platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("aarch64", "macos"),
]


products = [
    LibraryProduct("libcgns", :libcgns),
    ExecutableProduct("cgnscheck", :cgnscheck),
    ExecutableProduct("cgnscompress", :cgnscompress),
    ExecutableProduct("cgnsconvert", :cgnsconvert),
    ExecutableProduct("cgnsdiff", :cgnsdiff),
    ExecutableProduct("cgnslist", :cgnslist),
    ExecutableProduct("cgnsnames", :cgnsnames),
]

dependencies = [
    Dependency("HDF5_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
