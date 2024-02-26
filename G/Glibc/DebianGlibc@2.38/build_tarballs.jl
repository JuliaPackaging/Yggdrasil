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
    "72a64bc334e9d74f9475ee307166c5112a88251c498a9244069ddeccf63f8c03"),)
script = glibc_script()
platforms =  filter(p -> libc(p) == "glibc" && arch(p) == "aarch64",
    supported_platforms())
products = Product[] # glibc_products()
dependencies = glibc_dependencies()

# Build the tarballs
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version=v"11", lock_microarchitecture=false)
