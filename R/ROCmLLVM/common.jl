"""
ROCm works only on x86_64 linux platforms.
"""
function rocm_platform_filter(platform)
    Sys.islinux(platform) &&
        platform.tags["arch"] == "x86_64" &&
        platform.tags["cxxstring_abi"] == "cxx11"
end
