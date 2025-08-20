using BinaryBuilder, Pkg

name = "CGNS"
version = v"4.5.0"

sources = [
    GitSource("https://github.com/CGNS/CGNS.git",
              "c64b4abf7f5e9ca28c1afa3a4609efca961cee02"),
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

H5LIB=""
if [[ "${target}" == *-mingw* ]]; then
    H5LIB="-DHDF5_hdf5_LIBRARY_RELEASE=$(ls ${WORKSPACE}/destdir/bin/libhdf5-*.${dlext})"
fi
cmake -Bbuild -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
    -DCGNS_ENABLE_SHARED_LIB=YES \
    -DCGNS_ENABLE_STATIC_LIB=NO \
    ${H5LIB}
cmake --build build --parallel ${nproc}
cmake --install build
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
    # Without OpenMPI as build dependency the build fails on 32-bit platforms
    BuildDependency(PackageSpec(; name="OpenMPI_jll", version=v"4.1.8"); platforms=filter(p -> nbits(p)==32, platforms)),
    Dependency("HDF5_jll"; compat="~1.14.6"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
