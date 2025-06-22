# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SZ"
version = v"2.1.13"
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

hdf5_options=()
# HDF5 is available, use it.
# The HDF5 SZ filter does not work on Windows, so don't build it there.
# (The created shared library `libhdf5sz.dll` links to the wrong SO version of HDF5.)
if test -f "${includedir}/hdf5.h" && [[ $target != *-mingw* ]]; then
    hdf5_options+=(-DBUILD_HDF5_FILTER=ON -DBUILD_NETCDF_READER=ON)
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
    -DBUILD_PASTRI=ON \
    ${hdf5_options[@]} \
    ..
cmake --build . --config RelWithDebInfo --parallel ${nproc}
cmake --build . --config RelWithDebInfo --parallel ${nproc} --target install
install_license ../copyright-and-BSD-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libhdf5sz", :libhdf5sz),
    LibraryProduct("libnetcdfsz", :libnetcdfsz),
    LibraryProduct("libSZ", :libSZ),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    # For OpenMP we use libomp from `LLVMOpenMP_jll` where we use LLVM as compiler (BSD 
    # systems), and libgomp from `CompilerSupportLibraries_jll` everywhere else. 
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae");
               platforms=filter(!Sys.isbsd, platforms)),
    Dependency(PackageSpec(name="LLVMOpenMP_jll", uuid="1d63c593-3942-5779-bab2-d838dc0a180e");
               platforms=filter(Sys.isbsd, platforms)),
    # We had to restrict compat with HDF5 because of ABI breakage:
    # https://github.com/JuliaPackaging/Yggdrasil/pull/10347#issuecomment-2662923973
    # Updating to a newer HDF5 version is likely possible without problems but requires rebuilding this package
    Dependency("HDF5_jll"; compat="1.14.0 - 1.14.3"),
    Dependency("NetCDF_jll"),
    Dependency("Zlib_jll"),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 8 since we require newer features of C++17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6")
