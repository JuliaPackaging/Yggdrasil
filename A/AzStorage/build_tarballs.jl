# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "AzStorage"
version = v"0.1.0"

# Collection of sources required to build AzStorage
sources = [
    GitSource(
        "https://github.com/ChevronETC/AzStorage.jl.git",
        "c043e64b8a453f9a580c973c4f5cf0a84b142e6c"
    )
]

# Bash recipe for building across all platforms
script = raw"""
cd ${WORKSPACE}/srcdir/AzStorag/src

# We need to tell the makefile where to find libssh2 on windows
if [[ ${target} == *mingw* ]]; then
    export LDFLAGS="-L${WORKSPACE}/destdir/bin"
fi

make

if [[ ${target} == *mingw* ]]; then
    cp libAzStorage.so ${libdir}/libAzStorage.dll
elif [[ ${target} == *apple* ]]; then
    cp libAzStorage.so ${libdir}/libAzStorage.dylib
else
    cp libAzStorage.so ${libdir}/libAzStorage.so
fi
"""