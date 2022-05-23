module MicroArchitectures

const augment = """
    using Base.BinaryPlatforms: arch, arch_march_isa_mapping, CPUID, HostPlatform, Platform

    function augment_microarchitecture!(platform::Platform)
        haskey(platform, "march") && return platform

        host_arch = arch(HostPlatform())
        host_isas = arch_march_isa_mapping[host_arch]
        idx = findlast(((name, isa),) -> isa <= CPUID.cpu_isa(), host_isas)
        platform["march"] = first(host_isas[idx])
        return platform
    end
    """

end
