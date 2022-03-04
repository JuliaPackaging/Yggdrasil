module MPI

const tag_name = "mpi"

const augment = raw"""
    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    MPIPreferences_UUID = Base.UUID("3da0fdf6-3ccc-4f1b-acd9-58baa6c99267")
    const preferences = Base.get_preferences(MPIPreferences_UUID)

    # Keep logic in sync with MPIPreferences.jl
    # FIXME: When MPIPreferences is registered both `binary` and `abi` should be const
    #        and the jll packages using this tag shall depend on MPIPreferences.jl
    function augment_mpi!(platform)
        binary = get(preferences, "binary", Sys.iswindows() ? "MicrosoftMPI_jll" : "MPICH_jll")

        abi = if binary == "system"
            get(preferences, "abi")
        elseif binary == "MicrosoftMPI_jll"
            "MicrosoftMPI"
        elseif binary == "MPICH_jll"
            "MPICH"
        elseif binary == "OpenMPI_jll"
            "OpenMPI"
        elseif binary == "MPItrampoline_jll"
            "MPIwrapper"
        else
            error("Unknown binary: $binary")
        end

        if !haskey(platform, "mpi")
            platform["mpi"] = abi
        end
        return platform
    end
"""

using BinaryBuilder, Pkg
using Base.BinaryPlatforms

mpi_abis = (
    ("MPICH", PackageSpec(name="MPICH_jll"), "", !Sys.iswindows) ,
    ("OpenMPI", PackageSpec(name="OpenMPI_jll"), "", !Sys.iswindows),
    ("MicrosoftMPI", PackageSpec(name="MicrosoftMPI_jll"), "", Sys.iswindows),
    ("MPIwrapper", PackageSpec(name="MPItrampoline_jll"), "", !Sys.iswindows)
)

function augment_platforms(platforms)
    all_platforms = AbstractPlatform[]
    dependencies = []
    for (abi, pkg, compat, f) in mpi_abis
        pkg_platforms = deepcopy(filter(f, platforms))
        foreach(pkg_platforms) do p
            p[tag_name] = abi
        end
        append!(all_platforms, pkg_platforms)
        push!(dependencies, Dependency(pkg; compat, platforms=pkg_platforms))
    end
    return all_platforms, dependencies
end

end