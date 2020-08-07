#!/usr/bin/env julia
#
# Example usage:
#
#   julia reproducibility_scanning_tools.jl libusb
#
# Alternatively, you can get a shell and interactively do things:
#
#   julia -i reproducibility_scanning_tools.jl
#
#      julia> check_project("libusb")
#      julia> do_full_test()

using Random, SHA, JSON, BinaryBuilder, Tar, TranscodingStreams, CodecZlib, SimpleBufferStream

skip_dirs = ("0_RootFS",)
skip_projects = ("OpenBLAS", "LLVM")

function decompress!(input::IO, output::IO; blocksize::Int = 2*1024*1024)
    output = TranscodingStream(GzipDecompressor(), output)

    # Write that first chunk, then all the rest
    while !eof(input)
        write(output, read(input, blocksize))
    end

    # Close the TranscodingStream (we expect the caller to close the real `output`)
    close(output)
end

function collect_projects(root::AbstractString = @__DIR__)
    projects = String[]
    for d in readdir(root; join=true)
        if !isdir(d) || basename(d) in skip_dirs
            continue
        end

        for proj in readdir(d; join=true)
            if !isdir(proj) || basename(proj) in skip_projects
                continue
            end
            if !isfile(joinpath(proj, "build_tarballs.jl"))
                continue
            end

            push!(projects, proj)
        end
    end
    return projects
end

function collect_platforms(project::AbstractString)
    platforms = String[]
    cd(project) do
        mktempdir() do tmpdir
            meta_json = joinpath(tmpdir, "meta.json")
            success(`$(Base.julia_cmd()) build_tarballs.jl --meta-json=$(meta_json)`)

            json = String(read(meta_json))
            buff = IOBuffer(strip(json)) 
            while !eof(buff)
                obj = BinaryBuilder.JSON.parse(buff)
                append!(platforms, get(obj, "platforms", String[]))
            end
        end
    end
    return platforms
end

function inlogdir(hdr)
    path = hdr.path
    if startswith(path, "./")
        path = path[3:end]
    end
    return dirname(path) == "logs"
end

function collect_tar_tree(io::IO;
                          HashType = SHA.SHA256_CTX,
                          buf::Vector{UInt8} = Vector{UInt8}(undef, Tar.DEFAULT_BUFFER_SIZE),)
    tree = Dict{String,Any}()
    Tar.read_tarball(!inlogdir, io; buf=buf) do hdr, parts
        isempty(parts) && return
        name = pop!(parts)
        node = tree
        for part in parts
            node′ = get(node, part, nothing)
            if !(node′ isa Dict)
                node′ = node[part] = Dict{String,Any}()
            end
            node = node′
        end
        if hdr.type == :directory
            node[name] = Dict{String,Any}()
            return
        end
        if hdr.type == :symlink
            mode = "120000"
            hash = Tar.git_object_hash("blob", HashType) do io
                write(io, hdr.link)
            end
        elseif hdr.type == :file
            mode = iszero(hdr.mode & 0o100) ? "100644" : "100755"
            hash = Tar.git_file_hash(io, hdr.size, HashType, buf=buf)
        else
            error("unsupported type for git tree hashing: $(hdr.type)")
        end
        node[name] = (mode, hash)
    end
    return tree
end

function collect_compressed_tar_tree(filename)
    open(filename) do io_gz
        io = BufferStream()
        t_decomp = @async decompress!(io_gz, io)
        t_tree = @async collect_tar_tree(io)
        wait(t_decomp)
        return fetch(t_tree)
    end
end

function compare(a::Dict, a_filename::AbstractString, b::Dict, b_filename::AbstractString, prefix::AbstractString = "/")
    function key_equivalence(test_dict, check_dict, check_filename)
        all_ok = true
        for k in keys(test_dict)
            if k ∉ keys(check_dict)
                @error("$(prefix)/$(k) not present in $(check_filename)")
                all_ok = false
            end
            if isa(test_dict[k], Dict) && !isa(check_dict[k], Dict)
                @error("$(prefix)/$(k) is not a directory in $(check_filename)")
                all_ok = false
            end
        end
        return all_ok
    end
    all_ok = true
    all_ok &= key_equivalence(a, b, b_filename)
    all_ok &= key_equivalence(b, a, a_filename)

    for k in keys(a)
        if isa(a[k], Dict)
            # Recurse into dicts
            all_ok &= compare(a[k], a_filename, b[k], b_filename, joinpath(prefix, k))
        else
            # Check permissions and hashes of leaf nodes
            a_perms, a_hash = a[k]
            b_perms, b_hash = b[k]

            if a_perms != b_perms
                @error("Permissions mismatch!", path=joinpath(prefix,k), a_filename, b_filename, a_perms, b_perms)
                all_ok = false
            end
            if a_hash != b_hash
                @error("Content hash mismatch!", path=joinpath(prefix,k), a_filename, b_filename, a_hash, b_hash)
                all_ok = false
            end
        end
    end
    return all_ok
end


function check_project(project, platform)
    cd(project) do
        rm("products"; recursive=true, force=true)
        rm("build"; recursive=true, force=true)
        # Do first build
        @info("Building $(project) for $(platform) for the first time...")
        run(`$(Base.julia_cmd()) --color=yes build_tarballs.jl --verbose --debug $(platform)`)
        for f in readdir("products"; join=true)
            mv(f, "$(f).old")
        end
        # Then do second build
        @info("Building $(project) for $(platform) for the second time...")
        run(`$(Base.julia_cmd()) --color=yes build_tarballs.jl $(platform)`)

        # Now compare everything except for the `log/` directory:
        for f in readdir("products"; join=true)
            if !isfile("$(f).old")
                continue
            end
            new_tree = collect_compressed_tar_tree(f)
            old_tree = collect_compressed_tar_tree("$(f).old")
            if !compare(new_tree, f, old_tree, "$(f).old")
                error("$(basename(project)) is not reproducible for $(platform)!")
            else
                @info("$(basename(project)) passes for $(platform)!")
            end
        end
    end
end

function check_project(project)
    if basename(project) == project && !isdir(project)
        project = joinpath(uppercase(project[1:1]), project)
    end
    if !isdir(project)
        error("Unknown project $(project)")
    end

    @info("Investigating $(project)")
    platforms = collect_platforms(project)

    # Try to build for linux64 if we can, as that's most convenient
    linux64_platforms = sort!(filter(p -> occursin("x86_64-linux-gnu", p), platforms))
    local initial_platform
    if isempty(linux64_platforms)
        initial_platform = first(platforms)
    else
        initial_platform = first(linux64_platforms)
    end

    # Perform initial build with initial platform
    check_project(project, initial_platform)

    # If that worked, check all other platforms too!
    for other_platform in platforms
        if other_platform == initial_platform
            continue
        end
        check_project(project, other_platform)
    end
end

# For the truly insane
function do_full_test()
    projects = collect_projects()
    for project in shuffle(projects)
        check_project(project)
    end
end

# Auto-run projects if given on command line:
if !isempty(ARGS)
    for project in ARGS
        check_project(project)
    end
else
    println("Tools loaded, try check_project(\"libusb\")")
end