# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "libpcap"
version = v"1.10.4"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/the-tcpdump-group/libpcap.git", "104271ba4a14de6743e43bcf87536786d8fddea4")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
cd libpcap
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target}
make
make install
exit
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()
filter!(p -> !(Sys.isapple(p) && arch(p) == "aarch64"), platforms)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libpcap", :libpcap)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
