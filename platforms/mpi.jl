module MPI

const tag_name = "mpi"

const augment = raw"""
    # Can't use Preferences since we might be running this very early with a non-existing Manifest
    MPIPreferences_UUID = Base.UUID("3da0fdf6-3ccc-4f1b-acd9-58baa6c99267")
    const preferences = Base.get_preferences(MPIPreferences_UUID)

    # Keep logic in sync with MPIPreferences.jl
    function augment_mpi!(platform)
        # Doesn't need to be `const` since we depend on MPIPreferences so we
        # invalidate the cache when it changes.
        binary = get(preferences, "binary", Sys.iswindows() ? "MicrosoftMPI_jll" : "MPICH_jll")

        abi = if binary == "system"
            let abi = get(preferences, "abi", nothing)
                if abi === nothing
                    error("MPIPreferences: Inconsistent state detected, binary set to system, but no ABI set.")
                else
                    abi
                end
            end
        elseif binary == "MicrosoftMPI_jll"
            "MicrosoftMPI"
        elseif binary == "MPICH_jll"
            "MPICH"
        elseif binary == "OpenMPI_jll"
            "OpenMPI"
        elseif binary == "MPItrampoline_jll"
            "MPItrampoline"
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
    ("MPItrampoline", PackageSpec(name="MPItrampoline_jll"), "", !Sys.iswindows)
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
    # NOTE: packages using this platform tag, must depend on MPIPreferences otherwise
    #       they will not be invalidated when the Preference changes.
    push!(dependencies, Dependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"); compat="0.1"))
    return all_platforms, dependencies
end

end
