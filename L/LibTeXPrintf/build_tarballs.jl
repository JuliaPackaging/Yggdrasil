# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "LibTeXPrintf"
version = v"1.11.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bartp5/libtexprintf.git", "275a89bbfeb132007027a0a0e0dea333a72e40e5")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libtexprintf/
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-static=no --enable-shared=yes --enable-fast-install=yes
make -j${nproc}
make install
mkdir -p ${prefix}/share/licenses/libtexprintf
cp COPYING ${prefix}/share/licenses/libtexprintf
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
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libtexprintf", :libtexprintf)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
