#!/usr/bin/env julia

using Pkg, SHA, BinaryBuilder, Pkg.BinaryPlatforms

include("common.jl")

if Sys.which("mksquashfs") == nothing
    error("Must install squashfs-tools!")
end

# Parse CLI args
verbose = "--verbose" in ARGS
debug = "--debug" in ARGS

# First, figure out the path to BB and see if we can modify Artifacts.toml
BB_DIR = dirname(dirname(pathof(BinaryBuilder)))
if uperm(joinpath(BB_DIR,"Artifacts.toml")) & 0x02 != 0x02
    error("Unable to write to $(BB_DIR)/Artifacts.toml: dev BinaryBuilder first!")
end

# Let's start by building the Rootfs. We don't want to deploy this one quite yet,
# since it doesn't get a jll package
build_tarballs("Rootfs")

# Next, build the PlatformSupport packages.
for target in supported_platforms()
    build_tarballs("PlatformSupport", triplet(target))
end

# Next, bulid the GCC packages
for gcc_version in ("4.8.5", "5.2.0", "6.1.0", "7.1.0", "8.1.0")
    for target in supported_platforms()
        build_tarballs("GCCBootstrap", "--gcc-version", gcc_version, triplet(target))
    end
end

# LLVM, Rust, etc...
build_tarballs("LLVMBootstrap")
build_tarballs("Rust")
build_tarballs("Go")
