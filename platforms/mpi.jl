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
        # Note: MPIPreferences uses `Sys.iswindows()` without the `platform` argument.
        binary = get(preferences, "binary", Sys.iswindows(platform) ? "MicrosoftMPI_jll" : "MPICH_jll")

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
    # Note: riscv64 is only disabled because BinaryBuilder doesn't support it yet, the respective MPI packages have been built.
    ("MPICH", PackageSpec(name="MPICH_jll"), "4.3.0 - 4", p -> !Sys.iswindows(p) && !(arch(p) == "riscv64")),
    ("OpenMPI", PackageSpec(name="OpenMPI_jll"), "4.1.8, 5", p -> !Sys.iswindows(p) && !(arch(p) == "riscv64") && !(arch(p) == "armv6l" && libc(p) == "glibc")),
    ("MicrosoftMPI", PackageSpec(name="MicrosoftMPI_jll"), "", Sys.iswindows),
    ("MPItrampoline", PackageSpec(name="MPItrampoline_jll"), "5.5.0 - 5", p -> !(Sys.iswindows(p) || libc(p) == "musl"))
)

"""
    augment_platforms(platforms; MPICH_compat = nothing, OpenMPI_compat = nothing, MicrosoftMPI_compat=nothing, MPItrampoline_compat=nothing)

This augments the platforms with different MPI versions. Compatibilities with different versions can be specified
"""
function augment_platforms(platforms;
                MPICH_compat = nothing,
                OpenMPI_compat = nothing,
                MicrosoftMPI_compat=nothing,
                MPItrampoline_compat=nothing)
    all_platforms = AbstractPlatform[]
    dependencies = []
    for (abi, pkg, compat, f) in mpi_abis

        # set specific versions of MPI packages
        if (abi=="OpenMPI" && !isnothing(OpenMPI_compat)) compat = OpenMPI_compat; end
        if (abi=="MPICH" && !isnothing(MPICH_compat)) compat = MPICH_compat; end
        if (abi=="MicrosoftMPI" && !isnothing(MicrosoftMPI_compat)) compat = MicrosoftMPI_compat; end
        if (abi=="MPItrampoline" && !isnothing(MPItrampoline_compat)) compat = MPItrampoline_compat; end

        pkg_platforms = deepcopy(filter(f, platforms))
        foreach(pkg_platforms) do p
            p[tag_name] = abi
        end
        append!(all_platforms, pkg_platforms)
        push!(dependencies, Dependency(pkg; compat, platforms=pkg_platforms))
    end
    # NOTE: packages using this platform tag, must depend on MPIPreferences otherwise
    #       they will not be invalidated when the Preference changes.
    push!(dependencies, RuntimeDependency(PackageSpec(name="MPIPreferences", uuid="3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"); compat="0.1", top_level=true))
    return all_platforms, dependencies
end

end
