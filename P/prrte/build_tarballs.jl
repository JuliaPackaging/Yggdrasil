# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "prrte"
version = v"2.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://github.com/openpmix/prrte/releases/download/v$(version)/prte-$(version).tar.bz2", "9f4abc0b1410e0fa74ed7b00cfea496aa06172e12433c6f2864d11b534becc25")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd prte-*
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} \
    --enable-shared \
    --with-libevent=${prefix} \
    --with-hwloc=${prefix} \
    --with-pmix=${prefix} \
    --without-tests-examples \
    --disable-man-pages
make -j${nproc}
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
    ExecutableProduct("prte", :prte)
    ExecutableProduct("prun", :prun)
    ExecutableProduct("prte_info", :prte_info)
    ExecutableProduct("prterun", :prterun)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="libevent_jll", uuid="1080aeaf-3a6a-583e-a51c-c537b09f60ec"))
    Dependency(PackageSpec(name="Hwloc_jll", uuid="e33a78d0-f292-5ffc-b300-72abe9b543c8"))
    Dependency(PackageSpec(name="PMIx_jll", uuid="32165bc3-0280-59bc-8c0b-c33b6203efab"), compat="4.1.0")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
