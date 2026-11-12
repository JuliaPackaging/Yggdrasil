# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# NetCDF plugin: HDF5 shuffle filter.
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCH5shuffle"

build_netcdf_plugin(ARGS, name, "lib__nch5shuffle", ["H5Zshuffle.c"],
                    [];
                    defines=[],
                    libs=[])
