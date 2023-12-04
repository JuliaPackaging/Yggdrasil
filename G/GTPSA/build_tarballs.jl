# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "GTPSA"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/mattsignorelli/gtpsa.git", "ed2c14eb096a9ecac3f483f9914c0c679765496d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd gtpsa/
if [[ $target == *"-apple-"* ]]
then
CC=gcc
CXX=g++
ln /workspace/destdir/lib/liblapack32.dylib /workspace/destdir/lib/liblapack.dylib
elif [[ $target == *"linux"* ]]
then
ln /workspace/destdir/lib/liblapack32.so /workspace/destdir/lib/liblapack.so
fi
cmake . -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN%.*}_gcc.cmake -DCMAKE_BUILD_TYPE=Release
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
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libgtpsa", :GTPSA)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="ReferenceBLAS_jll", uuid="ee697234-451c-51c9-b102-303d89a9c3a0"))
    Dependency(PackageSpec(name="LAPACK32_jll", uuid="17f450c3-bd24-55df-bb84-8c51b4b939e3"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"11.1.0")
