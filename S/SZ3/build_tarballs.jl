# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SZ3"
version = v"3.1.7"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/szcompressor/SZ3/releases/download/v$(version)/SZ3-$(version).zip",
                  "cf3ba7fae82f9483c4089963b9951ba9bf6b9eca5f712727fb92f2390b778aa8"),
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir
cd SZ3-*

hdf5_options=
if test -f "${includedir}/hdf5.h"; then
    # HDF5 is available, use it
    hdf5_options='-DBUILD_H5Z_FILTER=ON'
else
    # Create an empty library
    echo 'int SZ_no_hdf5;' >hdf5sz3.cxx
    c++ -fPIC -c hdf5sz3.cxx
    c++ -shared -o libhdf5sz3.${dlext} hdf5sz3.o
    install -Dvm 755 "libhdf5sz3.${dlext}" "${libdir}/libhdf5sz3.${dlext}"
fi

mkdir build
cd build
cmake \
    -DCMAKE_FIND_ROOT_PATH=${prefix} \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DBUILD_MDZ=ON \
    ${hdf5_options} \
    ..
cmake --build . --config RelWithDebInfo --parallel ${nproc}

# Fix permissions on generated file (chmod does not work)
cat SZ3ConfigVersion.cmake >SZ3ConfigVersion.cmake.tmp
mv SZ3ConfigVersion.cmake.tmp SZ3ConfigVersion.cmake

cmake --build . --config RelWithDebInfo --parallel ${nproc} --target install
install_license ../copyright-and-BSD-license.txt
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
platforms = expand_cxxstring_abis(platforms)

# SZ3 requires a 64-bit architecture (and Windows uses 32-bit size_t?)
filter!(p -> nbits(p) ≥ 64 && !Sys.iswindows(p), platforms)

# OpenMP is not supported. SZ3's cmake has a bug that is probably corrected on the master branch.
# Try re-enabling this for version > 3.1.7.
filter!(p -> !(arch(p) ∈ ["aarch64", "x86_64"] && Sys.isapple(p)), platforms)

# There are C++ build errors with musl: the type `uint` is not declared.
# Try re-enabling this for version > 3.1.7.
filter!(p -> libc(p) ≠ "musl", platforms)

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
    ExecutableProduct("mdz", :mdz),
    ExecutableProduct("mdz_smoke_test", :mdz_smoke_test),
    ExecutableProduct("sz3", :sz3),
    ExecutableProduct("sz3_smoke_test", :sz3_smoke_test),
    LibraryProduct("libhdf5sz3", :libhdf5sz3),
    LibraryProduct("libSZ3c", :libSZ3c),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae")),
    Dependency("GSL_jll"),
    Dependency("HDF5_jll"; platforms=hdf5_platforms),
    Dependency("Zstd_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
# Using GCC 8 since we require newer features of C++17.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6", preferred_gcc_version=v"8")
