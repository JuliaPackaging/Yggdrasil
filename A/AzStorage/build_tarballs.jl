# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "AzStorage"
version = v"0.6.0"

# Collection of sources required to build AzStorage
sources = [
    GitSource(
        "https://github.com/ChevronETC/AzStorage.jl.git",
        "4a0d10bd58334f2b44a8615f518d5b4b634f4633"
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

install -Dvm 755 libAzStorage.so "${libdir}/libAzStorage.${dlext}"
install -Dvm 644 AzStorage.h "${includedir}/AzStorage.h"
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)

# The products that we will ensure are always built
# TODO - add libgomp dependency
products = [
    LibraryProduct("libAzStorage", :libAzStorage),
    FileProduct("include/AzStorage.h", :AzStorage_h),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LibCURL_jll", v"7.73.0"),
    # MbedTLS is only an indirect dependency (through LibCURL), but we want to
    # be sure to have the right version of MbedTLS for the corresponding version
    # of Julia.
    BuildDependency(PackageSpec(; name="MbedTLS_jll", version=v"2.24.0")),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
