# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "DataEcon"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/bankofcanada/DataEcon.git",
        "c99b6b8ea8a5d500ba8d091b384d58a815b7db01")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/DataEcon/
# make test
# make clean
make all
cp -p bin/* src/daec.h LICENSE.md README.md $prefix/
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
# platforms = supported_platforms()
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="glibc"),
    Platform("i686", "windows";),
    Platform("x86_64", "windows";),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv6l", "linux"; call_abi="eabihf", libc="glibc"),
    Platform("armv7l", "linux"; call_abi="eabihf", libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc"),
    Platform("i686", "linux"; libc="musl"),
    Platform("x86_64", "linux"; libc="musl"),
    Platform("aarch64", "linux"; libc="musl"),
    Platform("armv6l", "linux"; call_abi="eabihf", libc="musl"),
    Platform("armv7l", "linux"; call_abi="eabihf", libc="musl"),
    Platform("x86_64", "freebsd";),
]


# The products that we will ensure are always built
products = [
    LibraryProduct(["libdaec", "daec"], :libdaec, ["."]),
    ExecutableProduct("sqlite3", :sqlite3shell, "."),
    FileProduct("daec.h", :daec_header),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"10.2.0")
