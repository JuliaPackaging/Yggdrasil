# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "ggml"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/ggerganov/ggml.git", "7eb0edf3118a48f036cc4bf23e8a1eaeb2ea7f02"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/ggml

if [[ "${target}" == *86*-linux-gnu ]]; then
   export LDFLAGS="-lrt"
fi
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_BUILD_TESTS=OFF \
    ..
make -j${nproc}
make install
install_license ../LICENSE
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
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "macos"; ),
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libggml", :libggml)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8.1.0")
