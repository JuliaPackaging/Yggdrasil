# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libwatcher"
version = v"2.0.5"

# Collection of sources required to build libwatcher
sources = [
    GitSource("https://github.com/JuliaPluto/watcher.git", "18d62d71091a0d9c1fb5c28375bcd7e417d39d66")
]

# Bash recipe for building across all platforms
script = raw"""
cd watcher*/
bash build.sh
install -m 755 build/libwatcher.${dlext} ${libdir}/libwatcher.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc="glibc"),
    Platform("x86_64", "macos"),
    Platform("aarch64", "macos"),
    Platform("x86_64", "windows"),
]
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libwatcher", :libwatcher),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency("LibUV_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")

