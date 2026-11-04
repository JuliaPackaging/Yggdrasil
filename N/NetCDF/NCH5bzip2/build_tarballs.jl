# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# NetCDF plugin: HDF5 bzip2 filter.
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCH5bzip2"

build_netcdf_plugin(ARGS, name, "lib__nch5bzip2", ["H5Zbzip2.c"],
                    [
    Dependency("Bzip2_jll"; compat="1.0.9"),
];
                    defines=[],
                    libs=["-lbz2"])
