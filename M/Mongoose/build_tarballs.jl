# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "Mongoose"
version = v"7.19.0"

# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/cesanta/mongoose.git", "739d78a45a8fa6595498df67d11cac3e39af8c0e"),
    DirectorySource("./bundled"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir
mkdir -p ${libdir}
if [[ "${target}" == *mingw* ]]; then
    LIBS="-lws2_32"
fi
cc -fPIC -O2 -shared mongoose/mongoose.c -o ${libdir}/libmongoose.${dlext} "${LIBS}"

install_license mongoose/LICENSE
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    LibraryProduct("libmongoose", :libmongoose)
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"5.2.0")
