# Building MPItrampoline and its dependencies

```sh
pushd M/MPItrampoline
rm -rf $HOME/.julia/dev/MPItrampoline_jll
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-libgfortran5
# julia --color=yes build_tarballs.jl --debug --verbose --deploy=eschnett/MPItrampoline_jll.jl x86_64-apple-darwin-libgfortran5
popd

pushd A/ADIOS2
rm -rf $HOME/.julia/dev/ADIOS2_jll
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-libgfortran5-mpi+mpitrampoline
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-libgfortran5-mpi+mpich
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-libgfortran5-mpi+openmpi
popd

# NOTE: `julia_version+1.6.3` fails
pushd O/openPMD_api
rm -rf $HOME/.julia/dev/openPMD_api_jll
# julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-julia_version+1.7.0-mpi+mpitrampoline,x86_64-apple-darwin-julia_version+1.8.0-mpi+mpitrampoline,x86_64-apple-darwin-julia_version+1.9.0-mpi+mpitrampoline
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-julia_version+1.8.0-mpi+mpitrampoline
popd

pushd A/AMReX
rm -rf $HOME/.julia/dev/AMReX_jll
julia --color=yes build_tarballs.jl --debug --verbose --deploy=local x86_64-apple-darwin-mpi+mpitrampoline
popd

pushd P/PETSc
???
popd
```
