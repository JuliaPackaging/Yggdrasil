# We're not actually going to invoke any compilers here, so we don't actually use BinaryBuilder.
using BinaryProvider

name = "BaseCompilerShard"
version = v"2018.08.27"

compiler_target = nothing
try
    global compiler_target = triplet(platform_key(ARGS[end]))
    if typeof(compiler_target) <:UnknownPlatform
        error()
    end
catch
    error("This is not a typical build_tarballs.jl!  Must provide exactly one platform as the last argument!")
end

function find_tarball(project, pattern)
    dir = joinpath("..", project, "products")
    if !isdir(dir)
        error("No $(project)/products directory?!")
    end

    pattern = Regex("$(pattern).*\\.tar\\.gz")
    for f in readdir(dir)
        if match(pattern, f) !== nothing
            return joinpath(dir, f)
        end
    end
    error("Could not find $(project) tarball matching $(pattern)!")
end

# We're going to install things into this prefix, then package it up as a .tar.gz
temp_prefix() do prefix
    # Install KernelHeaders
    headers_path = find_tarball("KernelHeaders", "KernelHeaders.*$(compiler_target)")
    @info("Unpacking $(headers_path)")
    unpack(headers_path, prefix.path)

    # Install Binutils
    binutils_path = find_tarball("Binutils", "Binutils-$(compiler_target)")
    @info("Unpacking $(binutils_path)")
    unpack(binutils_path, prefix.path)

    # Install Libc
    libc_path = ""
    if occursin("-gnu", compiler_target)
        # If we're a `-gnu` target, install Glibc.  We install version 2.17 on
        # x86_64 and i686, 2.19 on armv7l and aarch64, and 2.25 on ppc64le. These
        # versions are chosen through the time-tested method of "pick the earliest
        # one that works", so as to maximize compatibility.  We also do our best
        # to match versions of official Julia binaries.
        glibc_version_dict = Dict(
            :x86_64 => "2.17",
            :i686 => "2.17",
            :aarch64 => "2.19",
            :armv7l => "2.19",
            :powerpc64le => "2.25",
        )
        glibc_version = glibc_version_dict[arch(platform_key(compiler_target))]

        libc_path = find_tarball("Glibc", "Glibc.*$(glibc_version).*$(compiler_target)")
    elseif occursin("-musl", compiler_target)
        libc_path = find_tarball("Musl", "Musl.*$(compiler_target)")
    elseif occursin("-mingw", compiler_target)
        libc_path = find_tarball("Mingw", "Mingw.*$(compiler_target)")
    elseif occursin("-freebsd", compiler_target)
        libc_path = find_tarball("FreeBSDLibc", "FreeBSDLibc.*")
    elseif occursin("-darwin", compiler_target)
        libc_path = find_tarball("MacOSLibc", "MacOSLibc.*")
    else
        error("Don't know how to install a Libc for $(compiler_target)!")
    end
    @info("Unpacking $(libc_path)")
    unpack(libc_path, prefix.path)

    # Do a little bit of cleanup; at this point we don't care about logs, manifests, etc...
    rm(joinpath(prefix, "logs"); recursive=true, force=true)
    rm(joinpath(prefix, "manifests"); recursive=true, force=true)

    # Package this prefix up nice and tight
    out_path = joinpath(pwd(), "products", name)
    package(prefix, out_path, version; platform=platform_key(compiler_target), verbose=true, force=true)
end

