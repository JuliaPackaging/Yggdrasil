include("../../L/libjulia/common.jl")

function gap_platforms(; expand_julia_versions::Bool=false)
    if expand_julia_versions
        platforms = vcat(libjulia_platforms.(julia_versions)...)

        # we only care about 64bit builds
        filter!(p -> nbits(p) == 64, platforms)

        # Windows is not supported
        filter!(!Sys.iswindows, platforms)

        return platforms
    else
        platforms = union(julia_supported_platforms.(julia_versions)...)
        
        filter!(p -> nbits(p) == 64, platforms) # we only care about 64bit builds
        filter!(!Sys.iswindows, platforms)      # Windows is not supported

        filter!(p -> arch(p) != "riscv64", platforms) # riscv64 is not supported atm

        # TODO: re-enable FreeBSD aarch64 support once GAP_jll supports it
        filter!(p -> !(Sys.isfreebsd(p) && arch(p) == "aarch64"), platforms)

        return platforms
    end
end
