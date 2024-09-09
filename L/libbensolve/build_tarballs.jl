# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libbensolve"
version = v"2.1.0"

# Collection of sources required to complete build
sources = [
    ArchiveSource("https://users.fmi.uni-jena.de/~sa67leb/bensolve/files/bensolve-$(version).tgz", "f13c6708974553e346c5426c0471f395fc4de417b55ac9fb07978fa9d268f0a0")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/bensolve*/
cc -shared -fPIC -std=c99 -O3 -o libbensolve.$dlext *.c -lglpk -lm
install -Dvm 755 libbensolve.$dlext -t ${libdir}
install -Dvm 644 *.h -t ${includedir}
install_license /usr/share/licenses/GPL-3.0+
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("i686", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "glibc"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "glibc"),
    Platform("powerpc64le", "linux"; libc = "glibc"),
    Platform("i686", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("armv6l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("armv7l", "linux"; call_abi = "eabihf", libc = "musl"),
    Platform("x86_64", "macos"; ),
    Platform("aarch64", "macos"; ),
    Platform("x86_64", "freebsd"; ),
    Platform("i686", "windows"; ),
    Platform("x86_64", "windows"; )
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libbensolve", :libbensolve)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="GLPK_jll", uuid="e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
