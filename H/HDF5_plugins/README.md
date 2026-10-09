# HDF5 filter plugins (C implementations)

One recipe per filter of [HDFGroup/hdf5_plugins](https://github.com/HDFGroup/hdf5_plugins).
JLL names are `H5Z<filter>C`: the `H5Z` prefix is HDF5's filter namespace and the
`C` suffix marks the C implementation (leaving `H5Z<filter>` free for Julia ones).

| JLL | Filter id | Library | Codec dependency |
|---|---|---|---|
| `H5ZbitgroomC_jll` | 32022 | `libh5bitgroom` | – |
| `H5ZbitroundC_jll` | 32032 | `libh5bitround` | – |
| `H5ZgranularbrC_jll` | 32023 | `libh5granular_bitround` | – |
| `H5ZbloscC_jll` | 32001 | `libh5blosc` | `Blosc_jll` |
| `H5Zblosc2C_jll` | 32026 | `libh5blosc2` | `Blosc2_jll` |
| `H5ZbshufC_jll` | 32008 | `libh5bshuf` | `Lz4_jll`, `Zstd_jll` (bitshuffle bundled upstream) |
| `H5Zbzip2C_jll` | 307 | `libh5bz2` | `Bzip2_jll` |
| `H5ZjpegC_jll` | 32019 | `libh5jpeg` | `JpegTurbo_jll` |
| `H5Zlz4C_jll` | 32004 | `libh5lz4` | `Lz4_jll` |
| `H5ZlzfC_jll` | 32000 | `libh5lzf` | – (liblzf bundled upstream) |
| `H5ZzfpC_jll` | 32013 | `libh5zzfp` | `zfp_jll` |
| `H5ZzstdC_jll` | 32015 | `libh5zstd` | `Zstd_jll` |

## Versioning and HDF5_jll

All recipes share `common.jl`. They are versioned like the hdf5_plugins release
(`2.2.0`) and depend on `HDF5_jll` with `compat = "~2.2"`: bump both together.
HDF5_jll only exists as MPI variants and its headers include `mpi.h`, so the
plugins use the same `mpi` platform augmentation as `H/HDF5`.

## Loading

Plugins are installed to `lib/plugin` (`bin/plugin` on Windows), as upstream does,
so each JLL's plugin directory holds exactly one plugin and can be put on
`HDF5_PLUGIN_PATH` (or `H5PLappend`ed) as is:

```julia
using HDF5_jll, H5ZzstdC_jll
ENV["HDF5_PLUGIN_PATH"] = dirname(H5ZzstdC_jll.libh5zstd_path)  # before libhdf5 is first used
```
