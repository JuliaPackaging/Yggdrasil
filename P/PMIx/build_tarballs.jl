# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "PMIx"
version = v"3.2.1"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/pmix/pmix/releases/download/v3.2.1/pmix-3.2.1.tar.bz2", "7e5db8ada5828cf85c12f70db6bfcf777d13e5c4c73b2206bb5e394d47066a2b")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd pmix-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-pmi-backward-compatibility --enable-shared --with-libevent=${prefix} --with-hwloc=${prefix} --without-tests-examples --disable-man-pages
make -j
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
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libpmi", :libpmi),
    LibraryProduct("libpmi2", :libpmi2),
    LibraryProduct("libpmix", :libpmix)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libevent_jll", uuid="1080aeaf-3a6a-583e-a51c-c537b09f60ec"))
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
