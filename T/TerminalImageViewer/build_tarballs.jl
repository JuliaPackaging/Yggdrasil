# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "TerminalImageViewer"
version = v"1.0.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/stefanhaustein/TerminalImageViewer.git", "134ca7390986e6e61f29753f7a3f54794078ea67"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/TerminalImageViewer/src/main/cpp/
# We need to compile with GCC everywhere
export CXX=g++
make
make prefix=${prefix} install
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
    Platform("armv7l", "linux"; libc="musl"),
    Platform("x86_64", "macos"),
    Platform("x86_64", "freebsd")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    ExecutableProduct("tiv", :tiv)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
