using BinaryBuilder

function machine_info(platform)
    if platform isa Linux
        system = "linux"
    elseif platform isa FreeBSD
        system = "freebsd"
    elseif platform isa MacOS
        system = "darwin"
    elseif platform isa Windows
        system = "windows"
    else
        error("Unknown system $(platform)")
    end

    if platform.arch === :aarch64
        cpu_family = "aarch64"
        cpu = "arm"
    elseif platform.arch === :armv7l
        cpu_family = "arm"
        cpu = "arm"
    elseif platform.arch === :i686
        cpu_family = "x86"
        cpu = "i686"
    elseif platform.arch === :powerpc64le
        cpu_family = "powerpc64"
        cpu = "i686"
    elseif platform.arch === :x86_64
        cpu_family = "x86_64"
        cpu = "i686"
    else
        error("Unknown CPU $(platform.arch)")
    end

    endian = "little"
    return system, cpu_family, cpu, endian
end

for target in supported_platforms()
    this_triplet = triplet(target)
    dir = this_triplet
    if isdir(dir)
        rm(dir, recursive=true, force=true)
    end
    mkdir(dir)

    host = Linux(:x86_64, libc=:glibc)
    mapping = BinaryBuilder.platform_envs(target, triplet(host))
    prefix = "/workspace/destdir"

    CC = split(mapping["CC"])[1]
    CXX = split(mapping["CXX"])[1]

    if length(mapping["CFLAGS"]) > 0
        C_ARGS = "'" * join(split(mapping["CFLAGS"]), "\', \'") * "\'"
    else
        C_ARGS= ""
    end
    if length(split(mapping["CC"])) > 1
        C_ARGS = "\'" * join(split(mapping["CC"])[2:end], "\', \'") * "\', " * C_ARGS
    end
    if length(split(mapping["CXX"])) > 1
        CXX_ARGS = "\'" * join(split(mapping["CXX"])[2:end], "\', \'") * "\'"
    else
        CXX_ARGS = ""
    end
    if length(split(mapping["LDFLAGS"])) > 0
        LDFLAGS = "'" * join(split(mapping["LDFLAGS"]), "\', \'") * "\'"
    else
        LDFLAGS = ""
    end

    host_system, host_cpu_family, host_cpu, host_endian = machine_info(host)
    target_system, target_cpu_family, target_cpu, target_endian = machine_info(target)

    cross_file = joinpath(dir, this_triplet * "_meson_cross_file.txt")

    content = """
[binaries]
c = '$CC'
cpp = '$CXX'
ar = '$(mapping["AR"])'
strip = '$(mapping["STRIP"])'
pkgconfig = '/usr/bin/pkg-config'

[properties]
c_args = [$(C_ARGS)]
cpp_args = [$(CXX_ARGS)]
link_args = [$(LDFLAGS)]

[host_machine]
system = '$(host_system)'
cpu_family = '$(host_cpu_family)'
cpu = '$(host_cpu)'
endian = '$(host_endian)'

[target_machine]
system = '$(target_system)'
cpu_family = '$(target_cpu_family)'
cpu = '$(target_cpu)'
endian = '$(target_endian)'

[paths]
prefix = '$(prefix)'
libdir = 'lib'
bindir = 'bin'
"""

    write(cross_file, content)
end
