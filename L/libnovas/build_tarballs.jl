# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libnovas"
version = v"3.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/kiranshila/novas.git", "0d4d08650d3b8a0f798da2b86f894b5083654e32")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/novas
autoreconf -i -f
if [[ "${target}" == *-freebsd* ]] || [[ "${target}" == *-apple-* ]]; then
    CC=gcc;
fi
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
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


# The products that we will ensure are always built
products = [
    LibraryProduct("libnovas", :libnovas)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
