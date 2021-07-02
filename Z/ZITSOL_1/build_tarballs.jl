# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZITSOL_1"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www-users.cs.umn.edu/~saad/software/ITSOL/ZITSOL_1.tar.gz",
                  "0ce5e3cef5ec55966db843a0d716a47566303961ba638b915a1b599d7a7800bd")
]

# Bash recipe for building across all platforms
# generate CMakeLists.txt on the fly.
script = raw"""
cd $WORKSPACE/srcdir/ZITSOL_1

echo "cmake_minimum_required(VERSION 3.17)" >> CMakeLists.txt
echo "project(ZITSOL_1 C)" >> CMakeLists.txt
echo "enable_language(Fortran)" >> CMakeLists.txt
echo "include(\$ENV{WORKSPACE}/destdir/lib/cmake/lapack-3.9.0/lapack-config.cmake)" >> CMakeLists.txt
echo "file(GLOB SRCS *.c)" >> CMakeLists.txt
echo "file(GLOB SRCS2 LIB/*.c)" >> CMakeLists.txt
echo "list(FILTER SRCS2 EXCLUDE REGEX systimer)" >> CMakeLists.txt
echo "add_library(ZITSOL_1 SHARED \${SRCS} \${SRCS2} LIB/ztools.f)" >> CMakeLists.txt
echo "target_link_libraries(ZITSOL_1  \${LAPACK_LIBRARIES})" >> CMakeLists.txt
echo "target_include_directories(ZITSOL_1 PUBLIC LIB)" >> CMakeLists.txt
echo "install(TARGETS ZITSOL_1)" >> CMakeLists.txt

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# FreeBSD build failed with libgfortran_version=3.0.0
platforms = [Platform("i686", "linux"; libc = "glibc"),
             Platform("x86_64", "linux"; libc = "glibc"),
             Platform("aarch64", "linux"; libc = "glibc"),
             Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
             Platform("powerpc64le", "linux"; libc = "glibc"),
             Platform("i686", "linux"; libc = "musl"),
             Platform("x86_64", "linux"; libc = "musl"),
             Platform("aarch64", "linux"; libc = "musl"),
             Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
             Platform("x86_64", "freebsd";),
             Platform("i686", "windows"; ),
             Platform("x86_64", "windows"; )
             ]

platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libZITSOL_1", :libZITSOL_1)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
