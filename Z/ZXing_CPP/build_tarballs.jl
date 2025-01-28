# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ZXing_CPP"
version = v"2.3.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/zxing-cpp/zxing-cpp.git", "d6068bcebeb8fd9f0d35a99b00d202be86a14dbe")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd zxing-cpp/
git submodule update --init
cmake -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_CXX_STANDARD=20 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DZXING_READERS=ON -DZXING_WRITERS=NEW -DZXING_USE_BUNDLED_ZINT=ON -DZXING_C_API=ON -DZXING_EXPERIMENTAL_API=ON
cmake --build build --parallel ${nproc} --config Release
cmake --install build
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
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libZXing", :libZXing)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")
