using BinaryBuilder

name = "minio"
version = v"2.0.0"

# Collection of sources
sources = [
    # RELEASE.2025-07-23T15-54-02Z
    GitSource("https://github.com/minio/minio", "7ced9663e6a791fef9dc6be798ff24cda9c730ac"),
    ArchiveSource("https://github.com/phracker/MacOSX-SDKs/releases/download/10.15/MacOSX10.15.sdk.tar.xz",
                  "2408d07df7f324d3beea818585a6d990ba99587c218a3969f924dfcc4de93b62"),
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/minio
install_license LICENSE

if [[ "${target}" == x86_64-apple-darwin* ]]; then
    # Install a newer SDK to work around compilation failures
    pushd $WORKSPACE/srcdir/MacOSX10.*.sdk
    rm -rf /opt/${target}/${target}/sys-root/System
    cp -ra usr/* "/opt/${target}/${target}/sys-root/usr/."
    cp -ra System "/opt/${target}/${target}/sys-root/."
    popd
fi

mkdir -p ${bindir}
GO111MODULE=on CGO_ENABLED=1 GOTMPDIR=$WORKSPACE go build -o ${bindir}
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
