# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ImarisWriter"
version = v"0.0.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/JaneliaSciComp/ImarisWriter.git", "da070d3fce8a1da4ca739c9e91054261d2df79a7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ImarisWriter/
mkdir build && cd build
if [[ "${target}" == *-mingw* ]]; then
    FLAGS="-DHDF5_FALLBACK_LIBRARIES=${libdir}/libhdf5-0.dll"
fi
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    "${FLAGS}" \
    ..
make -j${nproc}
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
#
# Mac build fails due to lack of features.h. See H5_HAVE_FEATURES_H in
# /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/local/include/H5pubconf.h
# /opt/x86_64-apple-darwin14/x86_64-apple-darwin14/sys-root/usr/local/include/H5public.h
#
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("i686", "windows"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)


# The products that we will ensure are always built
products = [
    LibraryProduct("libbpImarisWriter96", :libbpImarisWriter96)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency(PackageSpec(name="HDF5_jll", uuid="0234f1f7-429e-5d53-9886-15a909be8d59"); compat="~1.12")
    Dependency(PackageSpec(name="Lz4_jll", uuid="5ced341a-0733-55b8-9ab6-a4889d929147"))
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"5.2.0")
