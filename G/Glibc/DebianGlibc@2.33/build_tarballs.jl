using BinaryBuilder

# This package builds debian glibc 2.33 for use as a replacement glibc in
# debian bookworm in order to address the lse initialization order issue.
# It is hopefully temporary until the upstream bug is fixed.


include("../common.jl")

name = "DebianGlibc"
version = v"2.38"

sources = glibc_sources(version)
push!(sources,
    ArchiveSource("http://deb.debian.org/debian/pool/main/g/glibc/glibc_2.38-6.debian.tar.xz",
    "c4dd741a08918861796cf62a8d3209a56d41d807344a7db481b73a4d17f726bc"),)
script = glibc_script()
platforms =  filter(p -> libc(p) == "glibc" && arch(p) == "aarch64",
    supported_platforms())
products = Product[] # glibc_products()
dependencies = glibc_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11", lock_microarchitecture=false)
