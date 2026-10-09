# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# C implementation of the HDF5 BSHUF filter from HDFGroup/hdf5_plugins
name = "H5ZbshufC"
version = hdf5_plugins_version

sources = hdf5_plugins_sources()

# Bash recipe for building across all platforms
script = hdf5_plugin_script("libh5bshuf", ["BSHUF/src/H5Zbshuf.c", "BSHUF/src/bitshuffle.c", "BSHUF/src/bitshuffle_core.c", "BSHUF/src/iochain.c"]; libs=raw"-llz4 -lzstd", cflags="-DZSTD_SUPPORT -IBSHUF/src")

platforms, platform_dependencies = hdf5_plugins_platforms()

products = [
    hdf5_plugin_product("libh5bshuf"),
]

dependencies = hdf5_plugin_dependencies(platform_dependencies,
    Dependency("Lz4_jll"; compat="1.10.0"),
    Dependency("Zstd_jll"; compat="1.5.7"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block=hdf5_plugin_augment_platform_block, julia_compat="1.10")
