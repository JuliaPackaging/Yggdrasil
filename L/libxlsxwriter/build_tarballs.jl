# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libxlsxwriter"
version = v"1.2.2"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/jmcnamara/libxlsxwriter.git", "21c11a2052162b24c121b766e4373b081ea07ff6")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libxlsxwriter/
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON
cmake --build build --parallel ${nproc}
cmake --install build
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; exclude=p -> Sys.iswindows(p) && arch(p) == "i686")

# The products that we will ensure are always built
products = [
    LibraryProduct("libxlsxwriter", :libxlsxwriter)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency(PackageSpec(name="Zlib_jll", uuid="83775a58-1f1d-513f-b197-d71354ab007a"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
