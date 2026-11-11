---
name: mpi-recipes
description: Rules for Yggdrasil recipes that use MPI. Use when a build_tarballs.jl depends on an MPI implementation, includes platforms/mpi.jl or calls MPI.augment_platforms, links libmpi, msmpi or mpif, or uses the mpi platform tag.
---

# MPI packages

MPI recipes use a platform-tag augmentation scheme so a single set of JLLs can be retargeted at runtime via `MPIPreferences.jl`; without a preference, MPICH is used (MicrosoftMPI on Windows). Five ABIs are supported (`MPIABI`, `MPICH`, `MPItrampoline`, `OpenMPI`, `MicrosoftMPI`); the orchestration lives in `platforms/mpi.jl`.

Standard recipe shape (see `H/HelloWorldMPI/HelloWorldMPIC` and `H/HelloWorldMPI/HelloWorldMPIFortran`):

```julia
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))
# ...
platforms = supported_platforms()
platforms = expand_gfortran_versions(platforms)   # if Fortran code
platforms, platform_dependencies = MPI.augment_platforms(platforms)
augment_platform_block = """
    using Base.BinaryPlatforms
    $(MPI.augment)
    augment_platform!(platform::Platform) = augment_mpi!(platform)
"""
append!(dependencies, platform_dependencies)
build_tarballs(...; augment_platform_block, ...)
```

`MPI.augment_platforms` expands each base platform into one variant per allowed ABI, adds an `mpi=<abi>` tag, and returns the matching `Dependency` list (including `MPIPreferences`). Its default compat bounds are good; only pass `MPICH_compat=` etc. when a package genuinely needs it.

Recurring gotchas:

- **Platform availability** per ABI is encoded in the `mpi_abis` table in `platforms/mpi.jl`; don't re-filter in the recipe.
- **Expand before augmenting**: call `expand_gfortran_versions`, `expand_cxxstring_abis`, etc. *before* `MPI.augment_platforms`. The MPI dependencies are restricted to the platforms that exist at augmentation time, so platforms added later get no MPI dependency. Filtering afterwards is fine.
- **Per-ABI linking** is selected with `if [[ ${bb_full_target} == *mpiabi* ]]; then …` blocks. Each ABI provides different libraries (C, then Fortran):
  - `mpiabi`: `libmpi_abi`; `libmpif` (from `mpif_jll`)
  - `mpich`: `libmpi`; `libmpifort`
  - `mpitrampoline`: `libmpitrampoline`
  - `openmpi`: `libmpi`; `libmpi_mpifh`, `libmpi_usempif08`, `libmpi_usempi_ignore_tkr`
  - `microsoftmpi`: `msmpi64`
- **MPItrampoline compiler wrappers** remember the compilers MPItrampoline was built with. Recipes using `mpicc` etc. must `export MPITRAMPOLINE_CC=${CC} MPITRAMPOLINE_CXX=${CXX} MPITRAMPOLINE_FC=${FC}`.
- **Windows (MicrosoftMPI)** needs `-DMPI_HOME=${prefix} -DMPI_GUESS_LIBRARY_NAME=MSMPI` and `-DMPI_C_LIBRARIES=msmpi64` (likewise `MPI_CXX_LIBRARIES`) for CMake.
- **MPIABI** provides only the C bindings. Packages that call MPI from Fortran get the Fortran bindings from `mpif_jll`, added for the MPIABI platforms only: `Dependency("mpif_jll"; compat="1.0.1", platforms=filter(p -> p["mpi"] == "mpiabi", platforms))`, where `platforms` is the result of `MPI.augment_platforms`. See `H/HelloWorldMPI/HelloWorldMPIFortran`.
