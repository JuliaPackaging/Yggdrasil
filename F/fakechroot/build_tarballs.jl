# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "fakechroot"
version = v"2.20.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/dex4er/fakechroot.git", "b42d1fb9538f680af2f31e864c555414ccba842a")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/fakechroot
./autogen.sh 
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make -j${nproc}
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc="glibc"),
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("aarch64", "linux"; libc="glibc"),
    Platform("armv7l", "linux"; libc="glibc"),
    Platform("powerpc64le", "linux"; libc="glibc")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libfakechroot", :libfakechroot, ["lib/fakechroot"])
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
