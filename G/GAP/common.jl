include("../../L/libjulia/common.jl")

function gap_platforms(; expand_julia_versions::Bool=false)
    supported_julia_versions = filter(v -> v >= v"1.10", julia_versions)
    if expand_julia_versions
        platforms = vcat(libjulia_platforms.(supported_julia_versions)...)
    else
        platforms = union(julia_supported_platforms.(supported_julia_versions)...)
    end

    # we only care about 64bit builds
    filter!(p -> nbits(p) == 64, platforms)

    # Windows is not supported
    filter!(!Sys.iswindows, platforms)

    return platforms
end
