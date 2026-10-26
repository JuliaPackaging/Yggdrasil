# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# NetCDF plugin: HDF5 deflate (zlib) filter.
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCH5deflate"

build_netcdf_plugin(ARGS, name, "lib__nch5deflate", ["H5Zdeflate.c"],
                    [
    Dependency("Zlib_jll"; compat="1.2.12"),
];
                    defines=[],
                    libs=["-lz"])
