# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ITSOL_2"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://www-users.cs.umn.edu/~saad/software/ITSOL/ITSOL_2.tar.gz",
                  "80c1848f7f25c38e32090063233ef4a9ce9ea7b8e817774041085574a2ba59b0")
]

# Bash recipe for building across all platforms
# generate CMakeLists.txt on the fly. The ITSOL_2 provided makefile is rather limited build definition.
script = raw"""
cd $WORKSPACE/srcdir
cd ITSOL_2

echo "cmake_minimum_required(VERSION 3.17)" >> CMakeLists.txt
echo "project(ITSOL_2 C)" >> CMakeLists.txt
echo "enable_language(Fortran)" >> CMakeLists.txt
echo "include(\$ENV{WORKSPACE}/destdir/lib/cmake/lapack-3.9.0/lapack-config.cmake)" >> CMakeLists.txt
echo "file(GLOB SRCS SRC/*.c)" >> CMakeLists.txt
echo "# remove some unnecessary files from build" >> CMakeLists.txt
echo "list(FILTER SRCS EXCLUDE REGEX indsetC)" >> CMakeLists.txt
echo "list(FILTER SRCS EXCLUDE REGEX setblks)" >> CMakeLists.txt
echo "list(FILTER SRCS EXCLUDE REGEX systimer)" >> CMakeLists.txt
echo "list(SUBLIST SRCS 0 -1 VBILUK)" >> CMakeLists.txt
echo "list(FILTER VBILUK INCLUDE REGEX vbiluk)" >> CMakeLists.txt
echo "file(READ \${VBILUK} VBILUKSTR)" >> CMakeLists.txt
# rename multiple defined function 'lofC'
echo "string(REPLACE \\"int lofC(\\" \\"int lofC2(\\" VBILUKSTR2 \\"\${VBILUKSTR}\\")" >> CMakeLists.txt
echo "file(WRITE \${VBILUK} \\"\${VBILUKSTR2}\\")" >> CMakeLists.txt
echo "add_library(ITSOL_2 SHARED \${SRCS} SRC/tools.f)" >> CMakeLists.txt
echo "target_link_libraries(ITSOL_2  \${LAPACK_LIBRARIES})" >> CMakeLists.txt
echo "target_include_directories(ITSOL_2 PUBLIC INC)" >> CMakeLists.txt
echo "install(TARGETS ITSOL_2)" >> CMakeLists.txt

mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]

platforms = expand_gfortran_versions(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libITSOL_2", :libITSOL_2)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="LAPACK_jll", uuid="51474c39-65e3-53ba-86ba-03b1b862ec14")),
    Dependency(PackageSpec(name="OpenBLAS_jll", uuid="4536629a-c528-5b80-bd46-f80d51c5b363")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
