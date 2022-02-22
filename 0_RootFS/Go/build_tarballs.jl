using BinaryBuilder

include("../common.jl")

name = "Go"
version = v"1.17.7"

# https://go.dev/dl/
sources = [
    ArchiveSource(
        "https://go.dev/dl/go$(version).linux-amd64.tar.gz",
        "02b111284bedbfa35a7e5b74a06082d18632eff824fd144312f6063943d49259",
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
