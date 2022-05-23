# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SBC"
version = v"1.4.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirrors.edge.kernel.org/pub/linux/bluetooth/sbc-1.4.tar.gz", "050058cfc5a2709d324868ddbb82f9b796ba6c4f5e00cb6a715b3841ee13dfe9")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd sbc-1.4
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv7l", "linux"; libc="musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libsbc", :libsbc),
    ExecutableProduct("sbcenc", :sbcenc),
    ExecutableProduct("sbcinfo", :sbcinfo),
    ExecutableProduct("sbcdec", :sbcdec)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libsndfile_jll", uuid="5bf562c0-5a39-5b4f-b979-f64ac885830c"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
