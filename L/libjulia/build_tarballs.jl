include("common.jl")

# HACK HACK HACK: modify Pkg.jl in Julia 1.7 to allow us to install stdlib JLLs
# different from what was bundled with the Julia running this script.
# If/when we upgrade Yggdrasil to a newer version of Julia, this hack must be
# adjusted (ideally, with a new Pkg.jl it could be removed)
@assert v"1.7" <= VERSION < v"1.8"
function Pkg.Types.is_stdlib(uuid::Base.UUID, julia_version::VersionNumber)

    # Only use the cache if we are asking for stdlibs in a custom Julia version
    if julia_version == VERSION
        return Pkg.Types.is_stdlib(uuid)
    end

    # If this UUID is known to be unregistered, always return `true`
    if haskey(Pkg.Types.UNREGISTERED_STDLIBS, uuid)
        return true
    end

    last_stdlibs = Pkg.Types.get_last_stdlibs(julia_version)

    # BEGIN HACK
    if haskey(last_stdlibs, uuid)
        name, _ = last_stdlibs[uuid]
        return !endswith(name, "_jll")
    end
    # END HACK

    # Note that if the user asks for something like `julia_version = 0.7.0`, we'll
    # fall through with an empty `last_stdlibs`, which will always return `false`.
    return false
end

jllversion=v"1.10.15"
for ver in julia_full_versions
    build_julia(ARGS, ver; jllversion)
end
