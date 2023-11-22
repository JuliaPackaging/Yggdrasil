# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SEAL"
version = v"4.1.1"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/microsoft/SEAL.git", "206648d0e4634e5c61dcf9370676630268290b59")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd SEAL/
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_BUILD_TYPE=Release -DSEAL_USE_MSGSL=OFF -DSEAL_USE_ZLIB=OFF -DSEAL_BUILD_SEAL_C=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DSEAL_USE___BUILTIN_CLZLL=OFF 
cmake --build build
cmake --install build
install_license LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("aarch64", "linux"; libc = "musl"),
    Platform("x86_64", "linux"; libc = "musl"),
    Platform("aarch64", "linux"; libc = "glibc")
]

platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libsealc", :libsealc)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"10.2.0")

