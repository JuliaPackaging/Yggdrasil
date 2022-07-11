using BinaryBuilder

name = "minio"
version = v"1.0.0"

# Collection of sources
sources = [
    GitSource("https://github.com/minio/minio", "ed0cbfb31e00644013e6c2073310a2268c04a381"),
    FileSource("https://dl.min.io/server/minio/release/darwin-arm64/minio", "6a6710fa637aa4bd95a83ad43dd0e5a2ed223adeb18e45148d339aa8ca59cddc"; filename="miniobin")
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minio
install_license LICENSE
if [[ "${target}" == aarch64-apple-* ]]; then
    install -Dvm 755 ${WORKSPACE}/srcdir/miniobin ${bindir}/minio
    exit
fi
mkdir -p ${bindir}
GO111MODULE=on CGO_ENABLED=1 go build -o ${bindir}
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products = [
    ExecutableProduct("minio", :minio),
]

# Dependencies that must be installed before this package can be built
dependencies = Dependency[
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; compilers=[:c, :go], julia_compat="1.6")
