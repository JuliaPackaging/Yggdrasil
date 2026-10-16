# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../NetCDF/common.jl")

# NetCDF plugin: NCZarr codecs for the HDF5 standard filters (shuffle, fletcher32, deflate, szip).
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCZhdf5filters"

build_netcdf_plugin(ARGS, name, "lib__nczhdf5filters", ["NCZhdf5filters.c"],
                    [
    Dependency("libaec_jll"; compat="1.1.4"),
];
                    defines=["-DHAVE_SZ"],
                    libs=["-lnetcdf", "-lsz"], netcdf_runtime=true)
