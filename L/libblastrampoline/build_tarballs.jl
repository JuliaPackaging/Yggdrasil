# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "libblastrampoline"
version = v"3.1.0"

# Collection of sources required to build libblastrampoline
sources = [
    GitSource("https://github.com/staticfloat/libblastrampoline",
              "c6c7bc5d4ae088bd7c519d58e3fb8b686d00db0c")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libblastrampoline/src

make -j${nproc} prefix=${prefix} install
install_license /usr/share/licenses/MIT
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(;experimental=true)

# The products that we will ensure are always built
products = [
    LibraryProduct("libblastrampoline", :libblastrampoline)
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; 
               julia_compat="1.6",
               init_block = """
     ccall((:lbt_forward, libblastrampoline), Int32, (Cstring, Int32, Int32), path, clear ? 1 : 0, verbose ? 1 : 0)
"""

)
