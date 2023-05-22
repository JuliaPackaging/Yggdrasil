# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "isa_l"
version = v"2.30.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/intel/isa-l.git", "2bbce31943289d5696bcf2a433124c50928226a2")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/isa-l/
./autogen.sh
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]

# The products that we will ensure are always built
products = [
    LibraryProduct("libisal", :libisal),
    ExecutableProduct("igzip", :igzip)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    HostBuildDependency(PackageSpec(name="NASM_jll", uuid="08ca2550-6d73-57c0-8625-9b24120f3eae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
