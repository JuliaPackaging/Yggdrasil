# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "racket"
version = v"8.0.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://mirror.racket-lang.org/installers/8.0/racket-8.0-src.tgz", "921ee96ccb58af190124600aac8fe577444f1751a090c3f14879818d90ba1853")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd racket-8.0/
cd src/
mkdir build
cd build
../configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --enable-bc
make -j ${procs}
make -j ${procs} install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl")
]


# The products that we will ensure are always built
products = [
    FileProduct("lib/racket/mzdyn3m.o", :mzdyn3m),
    ExecutableProduct("gracketbc", :gracketbc, "lib/racket"),
    ExecutableProduct("starter", :starter, "lib/racket"),
    ExecutableProduct("mzschemebc", :mzschemebc),
    ExecutableProduct("racketbc", :racket),
    ExecutableProduct("mredbc", :mredbc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
