include("../common.jl")
include(joinpath(YGGDRASIL_DIR, "platforms", "mpi.jl"))

# This is the distributed build of AMGX. It is a separate package rather than a
# variant of AMGX_jll because MPI support changes the ABI: it defines
# AMGX_WITH_MPI, links MPI::MPI_CXX, and exposes the distributed entry points.
# Users who do not need MPI should keep using AMGX_jll, which doesn't need one
# build per MPI ABI.

platforms, mpi_dependencies = MPI.augment_platforms(platforms)

# Selection has to consider both the CUDA toolkit and the MPI ABI.
augment_platform_block = """
    using Base.BinaryPlatforms

    module __CUDA
        $(CUDA.augment)
    end

    $(MPI.augment)

    function augment_platform!(platform::Platform)
        augment_mpi!(platform)
        __CUDA.augment_platform!(platform)
    end
"""

# Don't look for `mpiwrapper.so` when BinaryBuilder examines and `dlopen`s the
# shared libraries. (MPItrampoline will skip its automatic initialization.)
ENV["MPITRAMPOLINE_DELAY_INIT"] = "1"

build_amgx("AMGX_MPI", platforms, mpi_dependencies, augment_platform_block)
