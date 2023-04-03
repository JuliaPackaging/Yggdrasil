# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SZ"
version = v"2.1.12"
version_string = "2.1.12.5"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/szcompressor/SZ/releases/download/v$(version_string)/SZ-$(version_string).tar.gz",
                  "32a820daf6019156a777300389d2392e4498a5c9daffce7be754cd0a5ba8729c"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd SZ-*

hdf5_options=
if test -f "${includedir}/hdf5.h"; then
    # HDF5 is available, use it
    hdf5_options='-DBUILD_HDF5_FILTER=ON -DBUILD_NETCDF_READER=ON'
else
    # Create an empty library
    echo 'int SZ_no_hdf5;' >hdf5sz.cxx
    c++ -fPIC -c hdf5sz.cxx
    c++ -shared -o libhdf5sz.${dlext} hdf5sz.o
    install -Dvm 755 "libhdf5sz.${dlext}" "${libdir}/libhdf5sz.${dlext}"
    # Create an empty library
    echo 'int SZ_no_netcdf;' >netcdfsz.cxx
    c++ -fPIC -c netcdfsz.cxx
    c++ -shared -o libnetcdfsz.${dlext} netcdfsz.o
    install -Dvm 755 "libnetcdfsz.${dlext}" "${libdir}/libnetcdfsz.${dlext}"
fi

mkdir build
cd build
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_OPENMP=ON \
    -DBUILD_PASTRI=ON \
     ${hdf5_options} \
    ..
cmake --build . --config RelWithDebInfo --parallel ${nproc}
cmake --build . --config RelWithDebInfo --parallel ${nproc} --target install
install_license ../copyright-and-BSD-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# # SZ requires a 64-bit architecture (and Windows uses 32-bit size_t?)
# filter!(p -> nbits(p) ≥ 64 && !Sys.iswindows(p), platforms)
# 
# # OpenMP is not supported. SZ's cmake has a bug that is probably corrected on the master branch.
# # Try re-enabling this for version > 3.1.7.
# filter!(p -> !(arch(p) ∈ ["aarch64", "x86_64"] && Sys.isapple(p)), platforms)
# 
# # There are C++ build errors with musl: the type `uint` is not declared.
# # Try re-enabling this for version > 3.1.7.
# filter!(p -> libc(p) ≠ "musl", platforms)

# The platforms where HDF5 is supported. See "HDF5/build_tarballs.jl".
hdf5_platforms = [
    Platform("x86_64", "linux"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "windows"),
    Platform("i686", "windows"),
    Platform("aarch64", "macos"),
]
hdf5_platforms = expand_cxxstring_abis(hdf5_platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libhdf5sz", :libhdf5sz),
    LibraryProduct("libnetcdfsz", :libnetcdfsz),
    LibraryProduct("libSZ", :libSZ),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("HDF5_jll"; platforms=hdf5_platforms),
    Dependency("NetCDF_jll"; platforms=hdf5_platforms),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 8 since we require newer features of C++17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6"
               # , preferred_gcc_version=v"8"
               )
