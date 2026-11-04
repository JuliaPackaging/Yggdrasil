# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# C implementation of the HDF5 JPEG filter from HDFGroup/hdf5_plugins
name = "H5ZjpegC"
version = hdf5_plugins_version

sources = hdf5_plugins_sources()

# Bash recipe for building across all platforms
script = hdf5_plugin_script("libh5jpeg", ["JPEG/src/H5Zjpeg.c"]; libs=raw"-ljpeg")

platforms = hdf5_plugins_platforms()

products = [
    hdf5_plugin_product("libh5jpeg"),
]

dependencies = hdf5_plugin_dependencies(platforms,
    Dependency("JpegTurbo_jll"; compat="3.2.0"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
