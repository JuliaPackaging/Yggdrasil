# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "open62541"
version = v"1.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/open62541/open62541.git", "ecf5a703785877a8719a0cda863a98455f7d5d12")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd open62541/
mkdir build
cd build/
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DUA_MULTITHREADING=100 -DUA_ENABLE_SUBSCRIPTIONS=ON -DUA_ENABLE_METHODCALLS=ON -DUA_ENABLE_PARSING=ON -DUA_ENABLE_NODEMANAGEMENT=ON -DUA_ENABLE_AMALGAMATION=ON -DUA_ENABLE_IMMUTABLE_NODES=ON -DBUILD_SHARED_LIBS=ON ..
make
make install
cd ..
install_license LICENSE
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
    Platform("x86_64", "macos"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libopen62541", :libopen62541)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
