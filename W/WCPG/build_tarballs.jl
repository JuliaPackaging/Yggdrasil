# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "WCPG"
version = v"0.9.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/remi-garcia/WCPG/archive/refs/tags/v0.9.1.tar.gz", "b794f0df05d8e0a42a077dafe445ddaba550659f370ef64a40ac84bc91c8b744"),
    FileSource("https://www.netlib.org/clapack/f2c.h", "7d323c009951dbd40201124b9302cb21daab2d98bed3d4a56b51b48958bc76ef"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/WCPG-0.9.1/
sh autogen.sh
./configure CFLAGS="-I${WORKSPACE}/srcdir/ -I${includedir}/" --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("x86_64", "freebsd"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libwcpg", :libwcpg)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("GMP_jll"; compat="6.1.2")
    Dependency("MPFR_jll")
    Dependency("MPFI_jll")
    Dependency("OpenBLAS_jll")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
