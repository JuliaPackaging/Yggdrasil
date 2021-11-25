# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Zlibcloudflare"
version = v"1.2.8"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cloudflare/zlib.git", "959b4ea305821e753385e873ec4edfaa9a5d49b7")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/zlib*
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DUNIX=true -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_SHARED_LIBS=ON
make -j ${nproc}
make install
install_license ../README
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Platform("x86_64", "linux"; libc = "glibc"),
    Platform("x86_64", "linux"; libc = "musl")
]


# The products that we will ensure are always built
products = [
    LibraryProduct("libz", :libz)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
