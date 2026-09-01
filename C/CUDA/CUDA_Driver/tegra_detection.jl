# Private Tegra platform detection used while selecting CUDA_Driver_jll's own
# artifact. This code runs in Pkg's standalone artifact-selection subprocess,
# where CUDA_Driver_jll cannot import itself. The artifact-independent
# `is_tegra` and `l4t_version` helpers are exposed publicly from `toplevel.jl`.

function _is_tegra()
    if isfile("/etc/nv_tegra_release")
        return true
    end
    if isfile("/proc/device-tree/compatible") &&
        contains(read("/proc/device-tree/compatible", String), "tegra")
        return true
    end
    return false
end

function _parse_l4t_version(release)
    m = match(r"^# R(\d+) \(release\), REVISION: ([0-9]+(?:\.[0-9]+)*)", release)
    m === nothing && return nothing
    return tryparse(VersionNumber, string(m.captures[1], ".", m.captures[2]))
end

function _l4t_version()
    try
        isfile("/etc/nv_tegra_release") || return nothing
        return _parse_l4t_version(read("/etc/nv_tegra_release", String))
    catch
        return nothing
    end
end

# _tegra_artifact_generation()
#
# Return the value of the `tegra` platform tag for the current host: "none" on
# non-Tegra systems, or the L4T major version (the kernel-mode driver generation,
# e.g. "35" for JetPack 5) bucketed to the generations we ship artifacts for:
# "32" (JetPack 4 and earlier: no compat driver exists), "35" (JetPack 5: compat
# drivers up to CUDA 12.2), "36" (JetPack 6: up to CUDA 12.9), and "38" (JetPack
# 7 and later, and unidentifiable L4T versions: no compat driver applies).
# This function never throws.
function _tegra_artifact_generation()
    tegra = try
        _is_tegra()
    catch
        false
    end
    tegra || return "none"

    try
        l4t = _l4t_version()
        l4t === nothing && return "38"
        if l4t.major < 35
            return "32"
        elseif l4t.major == 35
            return "35"
        elseif 36 <= l4t.major < 38
            return "36"
        else
            # JetPack 7+ (r38/r39), or a Tegra system whose L4T version we
            # cannot determine: no compat driver applies, so route to the
            # helper-only artifact.
            return "38"
        end
    catch
        # We already identified this as a Tegra host. If its L4T release cannot
        # be read, route it to a helper-only artifact rather than risk selecting
        # the incompatible SBSA driver.
        return "38"
    end
end
