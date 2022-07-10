using BinaryBuilder

name = "minio"
version = v"1.0.0"

# Collection of sources required to build ghr
sources = [
    GitSource("https://github.com/minio/minio", "ed0cbfb31e00644013e6c2073310a2268c04a381"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minio
mkdir -p ${bindir}
GO111MODULEgo build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("minio", :minio),
]

# Dependencies that must be installed before this package can be built
dependencies = [
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.7")
