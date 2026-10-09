# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# C implementation of the HDF5 BZIP2 filter from HDFGroup/hdf5_plugins
name = "H5Zbzip2C"
version = hdf5_plugins_version

sources = hdf5_plugins_sources()

# Bash recipe for building across all platforms
script = hdf5_plugin_script("libh5bz2", ["BZIP2/src/H5Zbzip2.c"]; libs=raw"-lbz2")

platforms, platform_dependencies = hdf5_plugins_platforms()

products = [
    hdf5_plugin_product("libh5bz2"),
]

dependencies = hdf5_plugin_dependencies(platform_dependencies,
    Dependency("Bzip2_jll"; compat="1.0.8"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               augment_platform_block=hdf5_plugin_augment_platform_block, julia_compat="1.10")
