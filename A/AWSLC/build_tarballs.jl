# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AWSLC"
version = v"1.0.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/awslabs/aws-lc.git", "11b50d39cf2378703a4ca6b6fee9d76a2e9852d1")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_LIBS=OFF -DBUILD_SHARED_LIBS=ON -GNinja aws-lc.git
ninja -j${nproc}
ninja install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcrypto", :libcrypto),
    LibraryProduct("libssl", :libssl),
    LibraryProduct("libdecrepit", :libdecrepit)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
