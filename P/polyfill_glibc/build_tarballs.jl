# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "polyfill_glibc"
version = v"0.1.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/corsix/polyfill-glibc.git", "f2005b78d6d0402ddc1079bcfb6db31a424f663b")
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/polyfill-glibc/
ninja -j${nproc} polyfill-glibc
install -Dvm 755 ./polyfill-glibc ${prefix}/bin/polyfill-glibc
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc")
]


# The products that we will ensure are always built
products = [
    ExecutableProduct("polyfill-glibc", :polyfill_glibc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
