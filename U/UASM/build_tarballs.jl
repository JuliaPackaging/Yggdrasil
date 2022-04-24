# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "UASM"
# Note: upstream doesn't tag new versions, but creates multiple versioned
# branches they keep pushing all the time, so it isn't even clear when a version
# is "stable".  Yes, you read it right.
version = v"2.55"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/Terraspace/UASM",
              "43bf08acc641166ee4766a33a5accc6e84535b3a"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/UASM*/
make -f gccLinux64.mak
install -Dvm 0755 "GccUnixR/uasm" "${bindir}/uasm${exeext}"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    # The build system is... uhm... complicated.  It's pointless to fight it for
    # multiple platforms, we need this mainly as a native tool when building.
    Platform("x86_64", "linux"; libc="musl"),
]

# The products that we will ensure are always built
products = [
    ExecutableProduct("uasm", :uasm),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"5")
