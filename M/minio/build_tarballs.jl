using BinaryBuilder

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "minio"
version = v"2.0.0"

# Collection of sources
sources = [
    # RELEASE.2025-07-23T15-54-02Z
    GitSource("https://github.com/minio/minio", "7ced9663e6a791fef9dc6be798ff24cda9c730ac"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minio
install_license LICENSE

mkdir -p ${bindir}
GO111MODULE=on CGO_ENABLED=1 GOTMPDIR=$WORKSPACE go build -o ${bindir}
"""

# Install a newer SDK to work around compilation failures
sources, script = require_macos_sdk("10.15", sources, script)

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
