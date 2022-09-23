using BinaryBuilder

name = "minio"
version = v"1.0.0"

# Collection of sources
sources = [
    GitSource("https://github.com/minio/minio", "20c89ebbb30f44bbd0eba4e462846a89ab3a56fa"),
    FileSource("https://dl.min.io/server/minio/release/darwin-arm64/minio", "6f650ba1119f9a456138e47ef3cabc0af08d40e4cce293c8d36392f8613528bb"; filename="miniobin")
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
dependencies = Dependency[]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               compilers=[:c, :go], julia_compat="1.6")
