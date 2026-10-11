# HDF5 filter plugins (C implementations)

One recipe per filter of [HDFGroup/hdf5_plugins](https://github.com/HDFGroup/hdf5_plugins).
JLL names are `H5Z<filter>C`: the `H5Z` prefix is HDF5's filter namespace and the
`C` suffix marks the C implementation (leaving `H5Z<filter>` free for Julia ones).

| JLL | Filter id | Library | Codec dependency |
|---|---|---|---|
| `H5ZzstdC_jll` | 32015 | `libh5zstd` | `Zstd_jll` |

The remaining filters of hdf5_plugins (bitgroom, bitround, granular bitround,
blosc, blosc2, bitshuffle, bzip2, jpeg, lz4, lzf, zfp) are added one per pull request.

## Versioning and HDF5_jll

All recipes share `common.jl`. They are versioned like the hdf5_plugins release
(`2.2.0`) and depend on `HDF5_jll` with `compat = "~2.2.3"`: bump both together.

The plugins do not use MPI, so they are built once per platform, not once per MPI
variant, and work with every HDF5_jll variant. HDF5_jll's headers include `mpi.h`,
so an MPI implementation (`MPICH_jll`, `MicrosoftMPI_jll` on Windows) is a
build-only dependency. Platforms are limited to the `libgfortran` 5 / `cxx11`
tags HDF5_jll is published for.

## Loading

Plugins are installed to `lib/plugin` (`bin/plugin` on Windows), as upstream does,
so each JLL's plugin directory holds exactly one plugin and can be put on
`HDF5_PLUGIN_PATH` (or `H5PLappend`ed) as is:

```julia
using HDF5_jll, H5ZzstdC_jll
ENV["HDF5_PLUGIN_PATH"] = dirname(H5ZzstdC_jll.libh5zstd_path)  # before libhdf5 is first used
```
