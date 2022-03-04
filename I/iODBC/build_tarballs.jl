# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "iODBC"
version = v"3.52.13"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/quinnj/iODBC.git", "ab2832e01a18260d1f89756dd445079e52718d4d")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd iODBC/
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make && make install
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


# The products that we will ensure are always built
products = [
    LibraryProduct("libiodbcinst", :libiodbcinst),
    ExecutableProduct("iodbctestw", :iodbctestw),
    LibraryProduct("libiodbc", :libiodbc),
    ExecutableProduct("iodbctest", :iodbctest)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
