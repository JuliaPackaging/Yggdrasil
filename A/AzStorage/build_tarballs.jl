# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "AzStorage"
version = v"0.3.0"

# Collection of sources required to build AzStorage
sources = [
    GitSource(
        "https://github.com/ChevronETC/AzStorage.jl.git",
        "2d45d02ac9a7b36a1e35e3e46dd54c73895a2c74"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AzStorage.jl/src

# We need to tell the makefile where to find libssh2 on windows
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${libdir}"
fi

make

cp libAzStorage.so ${libdir}/libAzStorage.${dlext}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
# TODO - add libgomp dependency
products = [
    LibraryProduct("libAzStorage", :libAzStorage)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    # libcurl changed compatibility version for macOS from v7.71 to v7.73 (v11
    # to v12)
    Dependency("LibCURL_jll", v"7.71.1"),
    # The following libraries are dependencies of LibCURL_jll which is now a
    # stdlib, but the stdlib doesn't explicitly list its dependencies
    Dependency("LibSSH2_jll"),
    Dependency("MbedTLS_jll", v"2.16.0"),
    Dependency("nghttp2_jll"),
    Dependency("Zlib_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
