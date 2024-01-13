### Instructions for adding a new version of the Go toolchain
#
# * find the latest stable releases at https://go.dev/dl/, update the `version`
#   variable and the SHA256 hash of the release tarball in the sources, the
#   expected checksum is provided in the download page.
# * To deploy the shard and automatically update your BinaryBuilderBase's
#   `Artifacts.toml`, use the `--deploy` flag to the `build_tarballs.jl` script.
#   You can build & deploy by running:
#
#      julia build_tarballs.jl --debug --verbose --deploy
#

using BinaryBuilder

include("../common.jl")

name = "Go"
version = v"1.21.6"
version_str = "1.21.6" # interpolating v1.21 would result in "1.21.0"

sources = [
    ArchiveSource(
        "https://go.dev/dl/go$(version_str).linux-amd64.tar.gz",
        "3f934f40ac360b9c01f616a9aa1796d227d8b0328bf64cb045c7b8c4ee9caea4",
    )
]

# Bash recipe for building across all platforms
script = raw"""
mv ${WORKSPACE}/srcdir/go ${prefix}/
"""

# We only build for host platform: x86_64-linux-musl
platforms = [
    host_platform,
]

# Dependencies that must be installed before this package can be built
dependencies = []

# The products that we will ensure are always built
products = [
    ExecutableProduct("go", :go, "go/bin"),
    ExecutableProduct("gofmt", :gofmt, "go/bin"),
]

# Build the tarballs, and possibly a `build.jl` as well.
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)

if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info)
end
