# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg
include("../common.jl")

# NetCDF plugin: NCZarr codecs for the bzip2, zstd and blosc filters.
# These only translate between NCZarr codec JSON and HDF5 filter parameters; the
# bzip2 and zstd libraries are not needed, only Blosc.
# Built from the plugin sources of netcdf-c against NetCDF_jll, see
# N/NetCDF/common.jl.

name = "NCZstdfilters"

build_netcdf_plugin(ARGS, name, "lib__nczstdfilters", ["NCZstdfilters.c"],
                    [
    Dependency("Blosc_jll"; compat="1.21.7"),
];
                    defines=["-DHAVE_ZSTD", "-DHAVE_BLOSC"],
                    libs=["-lnetcdf", "-lblosc"], netcdf_runtime=true)
