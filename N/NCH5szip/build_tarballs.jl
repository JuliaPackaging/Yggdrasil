# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../NetCDF/common.jl")

# NetCDF plugin: HDF5 szip filter (libaec provides libsz).
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCH5szip"

build_netcdf_plugin(ARGS, name, "lib__nch5szip", ["H5Zszip.c"],
                    [
    Dependency("libaec_jll"; compat="1.1.4"),
];
                    defines=["-DHAVE_SZ"],
                    libs=["-lsz"])
