# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "muesli"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://bitbucket.org/ignromero/muesli.git", "27e8204971602cb042d633b8b5f87761272b10df")
    DirectorySource(joinpath(@__DIR__, "bundled"))
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/muesli

atomic_patch -p1 ${WORKSPACE}/srcdir/patches/cmakesupport.patch

mkdir build &&  cd build && \
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --target install --parallel "$(nproc)" 
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv6l", "linux"; call_abi="eabihf", libc="glibc"),
    Platform("armv7l", "linux"; call_abi="eabihf", libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("riscv64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv6l", "linux"; call_abi="eabihf", libc="musl"),
    Platform("armv7l", "linux"; call_abi="eabihf", libc="musl"),
    # Platform("i686", "windows";),
    # Platform("x86_64", "windows";)
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = Product[
    LibraryProduct("libmuesli", :libmuesli)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"8")
