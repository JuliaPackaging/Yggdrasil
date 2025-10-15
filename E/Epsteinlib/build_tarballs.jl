# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Epsteinlib"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/epsteinlib/epsteinlib.git", "2a367d46d5f6a843858fc1b48beee9ce8eb4483d")
]

# Bash recipe for building across all platforms
script = raw"""
pip install cython
cd $WORKSPACE/srcdir/epsteinlib
perl -0777 -i -pe 's/true/false/' meson.options
meson setup build --cross-file=${MESON_TARGET_TOOLCHAIN} --buildtype=release
ninja -C build -j${nproc}
ninja -C build install
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
    Platform("riscv64", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("aarch64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libepstein", :libepstein),
    ExecutableProduct("epsteinlib_c-lattice_sum", :epsteinlib_c_lattice_sum)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
