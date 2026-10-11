# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# C implementation of the HDF5 ZSTD filter from HDFGroup/hdf5_plugins
name = "H5ZzstdC"
version = hdf5_plugins_version

sources = hdf5_plugins_sources()

# Bash recipe for building across all platforms
script = hdf5_plugin_script("libh5zstd", ["ZSTD/src/H5Zzstd.c"]; libs=raw"-lzstd")

platforms = hdf5_plugins_platforms()

products = [
    hdf5_plugin_product("libh5zstd"),
]

dependencies = hdf5_plugin_dependencies(platforms,
    Dependency("Zstd_jll"; compat="1.5.7"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
