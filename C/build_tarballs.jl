# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "CBFlib_small"
version = v"0.9.6"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jamesrhester/cbflib.git","d49aa5dd8802da4b584bd8f6db5ce6491fd2f2c4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release cbflib
make
make install
install_license ${WORKSPACE}/srcdir/cbflib/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "freebsd"; ),
    Platform("x86_64", "windows"; ),
    Platform("i686", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libcbf_small", :cbflib)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
