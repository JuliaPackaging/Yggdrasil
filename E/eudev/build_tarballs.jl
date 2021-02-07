# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "eudev"
version = v"3.2.9"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://dev.gentoo.org/~blueness/eudev/eudev-3.2.9.tar.gz", "89618619084a19e1451d373c43f141b469c9fd09767973d73dd268b92074d4fc")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/eudev*
apk add gperf
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
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
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libudev", :libudev),
    ExecutableProduct("udevd", :udevd, "sbin"),
    ExecutableProduct("udevadm", :udevadm)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="gperf_jll", uuid="1a1c6b14-54f6-533d-8383-74cd7377aa70"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
