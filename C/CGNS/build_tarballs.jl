using BinaryBuilder

name = "CGNS"
cgns_version = v"4.3.0"
version = v"4.3.1"

sources = [
    GitSource("https://github.com/CGNS/CGNS.git",
              "ec538ac11dbaff510464a831ef094b0d6bf7216c"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/CGNS*

if [[ ${target} == x86_64-linux-musl ]]; then
    # HDF5 needs libcurl, and it needs to be the BinaryBuilder libcurl, not the system libcurl
    rm /usr/lib/libcurl.*
    rm /usr/lib/libnghttp2.*
fi

# Correct HDF5 compiler wrappers
perl -pi -e 's+-I/workspace/srcdir/hdf5-1.14.0/src/H5FDsubfiling++' $(which h5pcc)

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

platforms = supported_platforms()

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
    Dependency("HDF5_jll"; compat="~1.14"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
