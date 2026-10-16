# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../NetCDF/common.jl")

# NetCDF plugin: HDF5 Zstandard filter.
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCH5zstd"

build_netcdf_plugin(ARGS, name, "lib__nch5zstd", ["H5Zzstd.c"],
                    [
    Dependency("Zstd_jll"; compat="1.5.7"),
];
                    defines=["-DHAVE_ZSTD"],
                    libs=["-lzstd"])
