# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# C implementation of the HDF5 LZ4 filter from HDFGroup/hdf5_plugins
name = "H5Zlz4C"
version = hdf5_plugins_version

sources = hdf5_plugins_sources()

# Bash recipe for building across all platforms
script = hdf5_plugin_script("libh5lz4", ["LZ4/src/H5Zlz4.c"]; libs=raw"-llz4 ${winsock_libs}", extra=raw"""
winsock_libs=
if [[ ${target} == *-mingw* ]]; then
    winsock_libs=-lws2_32
    plugin_flags+=(-DHAVE_WINSOCK2_H)
else
    # upstream gets these from its generated config header
    plugin_flags+=(-DHAVE_ARPA_INET_H -DHAVE_NETINET_IN_H)
fi
""")

platforms = hdf5_plugins_platforms()

products = [
    hdf5_plugin_product("libh5lz4"),
]

dependencies = hdf5_plugin_dependencies(platforms,
    Dependency("Lz4_jll"; compat="1.10.1"))

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.10")
