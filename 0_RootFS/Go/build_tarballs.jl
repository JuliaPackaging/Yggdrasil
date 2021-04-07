using BinaryBuilder

include("../common.jl")

name = "Go"
version = v"1.16.3"

# https://golang.org/dl/
sources = [
    ArchiveSource(
        "https://golang.org/dl/go1.16.3.linux-amd64.tar.gz",
        "951a3c7c6ce4e56ad883f97d9db74d3d6d80d5fec77455c6ada6c1f7ac4776d2",
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
]

# Build the tarballs, and possibly a `build.jl` as well.
ndARGS, deploy_target = find_deploy_arg(ARGS)
build_info = build_tarballs(ndARGS, name, version, sources, script, platforms, products, dependencies; skip_audit=true)

if deploy_target !== nothing
    upload_and_insert_shards(deploy_target, name, version, build_info)
end
